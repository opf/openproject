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
      belongs_to :cost_object, inverse_of: :work_packages
      has_many :cost_entries, dependent: :delete_all

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
                                           method(:cleanup_cost_entries_before_destruction_of)
    end
  end

  module ClassMethods
    protected

    def cleanup_cost_entries_before_destruction_of(work_packages, user, to_do = { action: 'destroy' })
      work_packages = Array(work_packages)

      return false unless to_do.present?

      case to_do[:action]
      when 'destroy'
        true
        # nothing to do
      when 'nullify'
        work_packages.each do |wp|
          wp.errors.add(:base, :nullify_is_not_valid_for_cost_entries)
        end

        false
      when 'reassign'
        reassign_to = WorkPackage
                      .where(Project.allowed_to_condition(user, :edit_cost_entries))
                      .includes(:project)
                      .references(:projects)
                      .find_by_id(to_do[:reassign_to_id])

        if reassign_to.nil?
          work_packages.each do |wp|
            wp.errors.add(:base, :is_not_a_valid_target_for_cost_entries, id: to_do[:reassign_to_id])
          end

          false
        else
          WorkPackage.update_cost_entries(work_packages.map(&:id), "work_package_id = #{reassign_to.id}, project_id = #{reassign_to.project_id}")
        end
      else
        false
      end
    end

    protected

    def update_cost_entries(work_packages, action)
      CostEntry.where(work_package_id: work_packages).update_all(action)
    end
  end

  module InstanceMethods
    def costs_enabled?
      project && project.costs_enabled?
    end

    def validate_cost_object
      if cost_object_id_changed?
        unless cost_object_id.blank? || project.cost_object_ids.include?(cost_object_id)
          errors.add :cost_object, :inclusion
        end
      end
    end

    def material_costs
      CostEntry.costs_of(work_packages: self)
    end

    def labor_costs
      TimeEntry.costs_of(work_packages: self)
    end

    def overall_costs
      labor_costs + material_costs
    end

    # Wraps the association to get the Cost Object subject.  Needed for the
    # Query and filtering
    def cost_object_subject
      unless cost_object.nil?
        return cost_object.subject
      end
    end

    def update_costs!
      # This methods ist referenced from some migrations but does nothing
      # anymore.
    end
  end
end

WorkPackage::SAFE_ATTRIBUTES << 'cost_object_id' if WorkPackage.const_defined? 'SAFE_ATTRIBUTES'
