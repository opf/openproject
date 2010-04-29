module CostQuery::GroupBy
  class Base < CostQuery::Chainable
    inherited_attributes :group_fields, :list => true

    def self.inherited(klass)
      klass.group_fields klass.field
      super
    end

    def filter?
      false
    end

    def sql_aggregation?
      child.filter?
    end
    
    def all_group_fields
      (parent ? parent.all_group_fields : []) + with_table(group_fields)
    end

    def aggregation_mixin
      sql_aggregation? ? SqlAggregation : RubyAggregation
    end 

    def initialize(child = nil, optios = {})
      super
      extend aggregation_mixin
    end

    def define_group(sql)
      fields = all_group_fields.uniq
      sql.group_by fields
      sql.select fields
    end
  end
end