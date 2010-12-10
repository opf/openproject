class Report::GroupBy
  class Base < Report::Chainable
    include Report::QueryUtils

    inherited_attributes :group_fields, :list => true, :merge => false

    def self.inherited(klass)
      klass.group_fields klass.field
      super
    end

    def correct_position?
      type == :row or !child.is_a?(engine::GroupBy::Base) or child.type == :column
    end

    def filter?
      false
    end

    def sql_aggregation?
      child.filter?
    end

    ##
    # @param [FalseClass, TrueClass] prefix Whether or not add a table prefix the field names
    # @return [Array<String,Symbol>] List of group by fields corresponding to self and all parents'
    def all_group_fields(prefix = true)
      @all_group_fields ||= []
      @all_group_fields[prefix ? 0 : 1] ||= begin
        fields = group_fields.reject { |c| c.blank? }
        (parent ? parent.all_group_fields(prefix) : []) + (prefix ? with_table(fields) : fields)
      end.uniq
    end

    def clear
      @all_group_fields = nil
      super
    end

    def aggregation_mixin
      sql_aggregation? ? SqlAggregation : RubyAggregation
    end

    def initialize(child = nil, optios = {})
      super
      extend aggregation_mixin
    end

    def result
      super
    end

    def compute_result
      super.tap do |r|
        r.type = type
        r.important_fields = group_fields
      end
    end

    def define_group(sql)
      fields = all_group_fields
      sql.group_by fields
      sql.select fields
    end
  end
end