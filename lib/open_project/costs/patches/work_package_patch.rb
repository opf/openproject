require 'work_package'

module OpenProject::Costs::Patches::WorkPackagePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable

      belongs_to :cost_object, :inverse_of => :work_packages
      has_many :cost_entries, :dependent => :delete_all

      # disabled for now, implements part of ticket blocking
      validate :validate_cost_object

      register_journal_formatter(:cost_association) do |value, journable, field|
        association = journable.class.reflect_on_association(field.to_sym)
        if association
          record = association.class_name.constantize.find_by_id(value.to_i)
          record.subject if record
        end
      end

      register_on_journal_formatter(:cost_association, 'cost_object_id')

      def spent_hours
        # overwritten method
        @spent_hours ||= self.time_entries.visible(User.current).sum(:hours) || 0
      end

      #safe_attributes "cost_object_id"
    end
  end

  module ClassMethods

  end

  module InstanceMethods
    def validate_cost_object
      if cost_object && cost_object.changed?
        unless (cost_object.blank? || project.cost_object_ids.include?(cost_object.id))
          errors.add :cost_object, :invalid
        end
      end
    end

    def material_costs
      @material_costs ||= cost_entries.visible_costs(User.current, self.project).sum("CASE
        WHEN #{CostEntry.table_name}.overridden_costs IS NULL THEN
          #{CostEntry.table_name}.costs
        ELSE
          #{CostEntry.table_name}.overridden_costs END").to_f
    end

    def labor_costs
      @labor_costs ||= time_entries.visible_costs(User.current, self.project).sum("CASE
        WHEN #{TimeEntry.table_name}.overridden_costs IS NULL THEN
          #{TimeEntry.table_name}.costs
        ELSE
          #{TimeEntry.table_name}.overridden_costs END").to_f
    end

    def overall_costs
      labor_costs + material_costs
    end

    # Wraps the association to get the Cost Object subject.  Needed for the
    # Query and filtering
    def cost_object_subject
      unless self.cost_object.nil?
        return self.cost_object.subject
      end
    end

    def update_costs!
      # This methods ist referenced from some migrations but does nothing
      # anymore.
    end
  end
end

WorkPackage::SAFE_ATTRIBUTES << "cost_object_id" if WorkPackage.const_defined? "SAFE_ATTRIBUTES"
WorkPackage.send(:include, OpenProject::Costs::Patches::WorkPackagePatch)
