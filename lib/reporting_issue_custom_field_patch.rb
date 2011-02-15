module ReportingIssueCustomFieldPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable

      # Update filter after each save, in case the available operators change
      after_save :generate_custom_field_filters
      # Update group bys after creation
      after_create :generate_custom_field_group_bys

      # Update auto-generated classes after removal
      after_destroy :generate_custom_field_group_bys
      after_destroy :generate_custom_field_filters
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
