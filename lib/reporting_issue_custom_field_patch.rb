module ReportingIssueCustomFieldPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable
      after_save :generate_custom_field_filters
      after_save :generate_custom_field_group_bys
    end
  end

  module InstanceMethods
    def generate_custom_field_filters
      CostQuery::Filter.reset!
      CostQuery::Filter::CustomFieldEntries.reset!
    end

    def generate_custom_field_group_bys
      CostQuery::GroupBy.reset!
      CostQuery::GroupBy::CustomFieldEntries.reset!
    end
  end
end

IssueCustomField.send(:include, ReportingIssueCustomFieldPatch)
