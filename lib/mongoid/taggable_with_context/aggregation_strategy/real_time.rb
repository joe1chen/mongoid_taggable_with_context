module Mongoid::TaggableWithContext::AggregationStrategy
  module RealTime
    extend ActiveSupport::Concern

    included do
      set_callback :save,     :after, :update_tags_aggregations_on_save
      set_callback :destroy,  :after, :update_tags_aggregations_on_destroy
    end
    
    module ClassMethods
      def tag_name_attribute
        "_id"
      end

      # Collection name for storing results of tag count aggregation

      def aggregation_database_collection_for(context)
        if Mongoid::Compatibility::Version.mongoid2?
          (@aggregation_database_collection ||= {})[context] ||= db.collection(aggregation_collection_for(context))
        elsif Mongoid::Compatibility::Version.mongoid3? || Mongoid::Compatibility::Version.mongoid4?
          (@aggregation_database_collection ||= {})[context] ||= Moped::Collection.new(self.collection.database, aggregation_collection_for(context))
        else
          (@aggregation_database_collection ||= {})[context] ||= Mongo::Collection.new(self.collection.database, aggregation_collection_for(context))
        end
      end

      def aggregation_collection_for(context)
        "#{collection_name}_#{context}_aggregation"
      end

      def tags_for(context, group_by = nil, conditions={})
        query(context, group_by, conditions).to_a.map{ |t| t[tag_name_attribute] }
      end

      # retrieve the list of tag with weight(count), this is useful for
      # creating tag clouds
      def tags_with_weight_for(context, group_by = nil, conditions={})
        query(context, group_by, conditions).to_a.map{ |t| [t[tag_name_attribute], t["value"].to_i] }
      end

      def recalculate_all_context_tag_weights!
        tag_contexts.each do |context|
          recalculate_tag_weights!(context)
        end
      end

      def recalculate_tag_weights!(context)
        db_field = self.class.tag_options_for(context)[:db_field]

        map = <<-END
        function() {
          if (!this.#{db_field})return;
          for (index in this.#{db_field})
            emit(this.#{db_field}[index], 1);
        }
        END

        reduce = <<-END
        function(key, values) {
          var count = 0;
          for (index in values) count += values[index];
          return count;
        }
        END

        if Mongoid::Compatibility::Version.mongoid2?
          collection.master.map_reduce(map, reduce, :out => aggregation_collection_for(context))
        else
          self.class.map_reduce(map, reduce).out(replace: aggregation_collection_for(context)).time
        end
      end

      # adapted from https://github.com/jesuisbonbon/mongoid_taggable/commit/42feddd24dedd66b2b6776f9694d1b5b8bf6903d
      def tags_autocomplete(context, criteria, options={})
        result = aggregation_database_collection_for(context).find({tag_name_attribute.to_sym => /^#{criteria}/})
        result = result.sort(value: -1) if options[:sort_by_count] == true
        result = result.limit(options[:max]) if options[:max] > 0
        result.to_a.map{ |r| [r[tag_name_attribute], r["value"]] }
      end

      protected
      def query(context, group_by, conditions)
        queryLimit = conditions.delete(:limit) if conditions[:limit]
        querySort = conditions.delete(:sort) if conditions[:sort]

        query = aggregation_database_collection_for(context).find({value: {"$gt" => 0 }}.merge(conditions || {}))

        query = query.limit(queryLimit) if queryLimit
        query = querySort ? query.sort(querySort) : query.sort(tag_name_attribute.to_sym => 1)
        query
      end

    end

    protected

    def get_conditions(context, tag)
      {self.class.tag_name_attribute.to_sym => tag}
    end
    
    def update_tags_aggregation(context, old_tags=[], new_tags=[])
      if Mongoid::Compatibility::Version.mongoid2?
        coll = self.class.db.collection(self.class.aggregation_collection_for(context))
      else
        coll = self.class.aggregation_database_collection_for(context)
      end

      old_tags ||= []
      new_tags ||= []
      unchanged_tags  = old_tags & new_tags
      tags_removed    = old_tags - unchanged_tags
      tags_added      = new_tags - unchanged_tags

      
      tags_removed.each do |tag|
        if Mongoid::Compatibility::Version.mongoid2?
          coll.update(get_conditions(context, tag), {'$inc' => {:value => -1}}, :upsert => true)
        elsif Mongoid::Compatibility::Version.mongoid3? || Mongoid::Compatibility::Version.mongoid4?
          coll.find(get_conditions(context, tag)).upsert({'$inc' => {value: -1}})
        else
          coll.find(get_conditions(context, tag)).update_many({'$inc' => {value: -1}}, { upsert: true })
        end
      end
      tags_added.each do |tag|
        if Mongoid::Compatibility::Version.mongoid2?
          coll.update(get_conditions(context, tag), {'$inc' => {:value => 1}}, :upsert => true)
        elsif Mongoid::Compatibility::Version.mongoid3? || Mongoid::Compatibility::Version.mongoid4?
          coll.find(get_conditions(context, tag)).upsert({'$inc' => {value: 1}})
        else
          coll.find(get_conditions(context, tag)).update_many({'$inc' => {value: 1}}, { upsert: true })
        end
      end
      #coll.find({_id: {"$in" => tags_removed}}).update({'$inc' => {:value => -1}}, [:upsert])
      #coll.find({_id: {"$in" => tags_added}}).update({'$inc' => {:value => 1}}, [:upsert])
    end
    
    def update_tags_aggregations_on_save
      indifferent_changes = HashWithIndifferentAccess.new changes
      self.class.tag_database_fields.each do |field|
        next if indifferent_changes[field].nil?

        old_tags, new_tags = indifferent_changes[field]
        update_tags_aggregation(field, old_tags, new_tags)
      end
    end
    
    def update_tags_aggregations_on_destroy
      self.class.tag_database_fields.each do |field|
        old_tags = send field
        new_tags = []
        update_tags_aggregation(field, old_tags, new_tags)
      end      
    end
  end
end
