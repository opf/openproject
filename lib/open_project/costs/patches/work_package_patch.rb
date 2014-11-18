#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

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

      associated_to_ask_before_destruction CostEntry,
                                           ->(work_packages) { CostEntry.on_work_packages(work_packages).count > 0 },
                                          self.method(:cleanup_cost_entries_before_destruction_of)
    end

  end

  module ClassMethods

    protected

    def cleanup_cost_entries_before_destruction_of(work_packages, user, to_do = { :action => 'destroy'} )
      return false unless to_do.present?

      case to_do[:action]
      when 'destroy'
        true
        # nothing to do
      when 'nullify'
        Array(work_packages).each do |wp|
          wp.errors.add(:base, :nullify_is_not_valid_for_cost_entries)
        end

        false
      when 'reassign'
        reassign_to = WorkPackage.includes(:project)
                                 .where(Project.allowed_to_condition(user, :edit_cost_entries))
                                 .find_by_id(to_do[:reassign_to_id])

        if reassign_to.nil?
          Array(work_packages).each do |wp|
            wp.errors.add(:base, :is_not_a_valid_target_for_cost_entries, id: to_do[:reassign_to_id])
          end

          false
        else
          WorkPackage.update_cost_entries(work_packages, "work_package_id = #{reassign_to.id}, project_id = #{reassign_to.project_id}")
        end
      else
        false
      end
    end

    protected

    def update_cost_entries(work_packages, action)
      CostEntry.update_all(action, ['work_package_id IN (?)', work_packages])
    end
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
