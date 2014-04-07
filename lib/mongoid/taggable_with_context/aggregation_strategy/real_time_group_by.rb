module Mongoid::TaggableWithContext::AggregationStrategy
  module RealTimeGroupBy
    extend ActiveSupport::Concern
    include Mongoid::TaggableWithContext::AggregationStrategy::RealTime

    module ClassMethods
      def tag_name_attribute
        "_name"
      end

      def tags_for(context, group_by, conditions={})
        results = if group_by
          query(context, group_by, conditions).to_a.map{ |t| t[tag_name_attribute] }
        else
          super(context, group_by, conditions)
        end
        results.uniq
      end

      def tags_with_weight_for(context, group_by, conditions={})
        results = if group_by
          query(context, group_by, conditions).to_a.map{ |t| [t[tag_name_attribute], t["value"].to_i] }
        else
          super(context, group_by, conditions)
        end

        tag_hash = {}
        results.each do |tag, weight|
          tag_hash[tag] ||= 0
          tag_hash[tag] += weight
        end
        tag_hash.to_a
      end

      protected
      def query(context, group_by, conditions)
        queryLimit = conditions.delete(:limit) if conditions[:limit]
        querySort = conditions.delete(:sort) if conditions[:sort]

        if group_by
          query = aggregation_database_collection_for(context).find({value: {"$gt" => 0 }, group_by: group_by}.merge(conditions || {}))
        else
          query = aggregation_database_collection_for(context).find({value: {"$gt" => 0 }}.merge(conditions || {}))
        end

        query = query.limit(queryLimit) if queryLimit
        query = querySort ? query.sort(querySort) : query.sort(tag_name_attribute.to_sym => 1)
        query
      end
    end

    protected

    def get_conditions(context, tag)
      conditions = {self.class.tag_name_attribute.to_sym => tag}
      group_by = self.class.get_tag_group_by_field_for(context)
      if group_by
        conditions.merge!({group_by: self.send(group_by)})
      end
      conditions
    end
  end
end