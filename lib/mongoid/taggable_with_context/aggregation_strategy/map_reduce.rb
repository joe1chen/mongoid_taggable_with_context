module Mongoid::TaggableWithContext::AggregationStrategy
  module MapReduce
    extend ActiveSupport::Concern
    included do
      set_callback :save,     :after, :map_reduce_all_contexts!, if: :tags_changed?
      set_callback :destroy,  :after, :map_reduce_all_contexts!
      delegate :aggregation_collection_for, to: "self.class"
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
        query(context, group_by, conditions).to_a.map{ |t| t["_id"] }
      end

      # retrieve the list of tag with weight(count), this is useful for
      # creating tag clouds
      def tags_with_weight_for(context, group_by = nil, conditions={})
        query(context, group_by, conditions).to_a.map{ |t| [t["_id"], t["value"].to_i] }
      end

      def query(context, group_by, conditions)
        queryLimit = conditions.delete(:limit) if conditions[:limit]
        querySort = conditions.delete(:sort) if conditions[:sort]

        query = aggregation_database_collection_for(context).find({value: {"$gt" => 0 }}.merge(conditions || {}))

        query = query.limit(queryLimit) if queryLimit

        query = querySort ? query.sort(querySort) : query.sort(_id: 1)
        query
      end
    end
    
    protected
    def changed_tag_arrays
      self.class.tag_database_fields & changes.keys.map(&:to_sym)
    end
    
    def tags_changed?
      !changed_tag_arrays.empty?
    end
    
    def map_reduce_all_contexts!
      self.class.tag_contexts.each do |context|
        map_reduce_context!(context)
      end
    end
    
    def map_reduce_context!(context)
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
  end
end
