module Mongoid::TaggableWithContext::AggregationStrategy
  module RealTimeGroupBy
    extend ActiveSupport::Concern
    include Mongoid::TaggableWithContext::AggregationStrategy::RealTime

    included do
      set_callback :save,     :after, :update_tags_group_by_aggregations_on_save
      set_callback :destroy,  :after, :update_tags_group_by_aggregations_on_destroy
    end

    module ClassMethods
      def tag_name_attribute_group_by
        "_name"
      end

      def aggregation_database_collection_group_by_for(context)
        if Mongoid::TaggableWithContext.mongoid2?
          (@aggregation_group_by_database_collection ||= {})[context] ||= db.collection(aggregation_collection_group_by_for(context))
        else
          (@aggregation_group_by_database_collection ||= {})[context] ||= Moped::Collection.new(self.collection.database, aggregation_collection_group_by_for(context))
        end
      end

      def aggregation_collection_group_by_for(context)
        "#{collection_name}_#{context}_group_by_aggregation"
      end

      def tags_for(context, group_by, conditions={})
        results = if group_by
                    group_by_query(context, group_by, conditions).to_a.map{ |t| t[tag_name_attribute_group_by] }
                  else
                    super(context, group_by, conditions)
                  end
        results.uniq
      end

      def tags_with_weight_for(context, group_by, conditions={})
        results = if group_by
                    group_by_query(context, group_by, conditions).to_a.map{ |t| [t[tag_name_attribute_group_by], t["value"].to_i] }
                  else
                    super(context, group_by, conditions)
                  end

        tag_hash = {}
        results.each do |tag, weight|
          tag_hash[tag] = weight
        end
        tag_hash.to_a
      end

      protected
      def group_by_query(context, group_by, conditions)
        queryLimit = conditions.delete(:limit) if conditions[:limit]
        querySort = conditions.delete(:sort) if conditions[:sort]

        query = aggregation_database_collection_group_by_for(context).find({value: {"$gt" => 0 }, group_by: group_by}.merge(conditions || {}))

        query = query.limit(queryLimit) if queryLimit
        query = querySort ? query.sort(querySort) : query.sort(tag_name_attribute_group_by.to_sym => 1)
        query
      end
    end

    protected

    def get_group_by_conditions(context, tag)
      conditions = {self.class.tag_name_attribute_group_by.to_sym => tag}
      group_by = self.class.get_tag_group_by_field_for(context)
      if group_by
        conditions.merge!({group_by: self.send(group_by)})
      end
      conditions
    end

    def update_tags_group_by_aggregation(context, old_tags=[], new_tags=[])
      if Mongoid::TaggableWithContext.mongoid2?
        coll = self.class.db.collection(self.class.aggregation_collection_group_by_for(context))
      else
        coll = self.class.aggregation_database_collection_group_by_for(context)
      end

      old_tags ||= []
      new_tags ||= []
      unchanged_tags  = old_tags & new_tags
      tags_removed    = old_tags - unchanged_tags
      tags_added      = new_tags - unchanged_tags


      tags_removed.each do |tag|
        if Mongoid::TaggableWithContext.mongoid2?
          coll.update(get_group_by_conditions(context, tag), {'$inc' => {:value => -1}}, :upsert => true)
        else
          coll.find(get_group_by_conditions(context, tag)).upsert({'$inc' => {value: -1}})
        end
      end
      tags_added.each do |tag|
        if Mongoid::TaggableWithContext.mongoid2?
          coll.update(get_group_by_conditions(context, tag), {'$inc' => {:value => 1}}, :upsert => true)
        else
          coll.find(get_group_by_conditions(context, tag)).upsert({'$inc' => {value: 1}})
        end
      end
      #coll.find({_id: {"$in" => tags_removed}}).update({'$inc' => {:value => -1}}, [:upsert])
      #coll.find({_id: {"$in" => tags_added}}).update({'$inc' => {:value => 1}}, [:upsert])
    end

    def update_tags_group_by_aggregations_on_save
      indifferent_changes = HashWithIndifferentAccess.new changes
      self.class.tag_database_fields.each do |field|
        next if indifferent_changes[field].nil?

        old_tags, new_tags = indifferent_changes[field]
        update_tags_group_by_aggregation(field, old_tags, new_tags)
      end
    end

    def update_tags_group_by_aggregations_on_destroy
      self.class.tag_database_fields.each do |field|
        old_tags = send field
        new_tags = []
        update_tags_group_by_aggregation(field, old_tags, new_tags)
      end
    end
  end
end