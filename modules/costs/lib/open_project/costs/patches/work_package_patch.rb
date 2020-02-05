#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require_dependency 'work_package'

module OpenProject::Costs::Patches
  module WorkPackagePatch
    def self.mixin!
      ::WorkPackage.prepend InstanceMethods
      ::WorkPackage.singleton_class.prepend ClassMethods

      ::WorkPackage.class_eval do
        belongs_to :cost_object, inverse_of: :work_packages
        has_many :cost_entries, dependent: :delete_all

        # disabled for now, implements part of ticket blocking
        validate :validate_cost_object

        after_update :move_cost_entries

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
          reassign_cost_entries_before_destruction(work_packages, user, to_do[:reassign_to_id])
        else
          false
        end
      end

      def reassign_cost_entries_before_destruction(work_packages, user, ids)
        reassign_to = ::WorkPackage
                      .joins(:project)
                      .merge(Project.allowed_to(user, :edit_cost_entries))
                      .find_by_id(ids)

        if reassign_to.nil?
          work_packages.each do |wp|
            wp.errors.add(:base, :is_not_a_valid_target_for_cost_entries, id: ids)
          end

          false
        else
          condition = "work_package_id = #{reassign_to.id}, project_id = #{reassign_to.project_id}"
          ::WorkPackage.update_cost_entries(work_packages.map(&:id), condition)
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

      def cost_reporting_enabled?
        project && project.cost_reporting_enabled?
      end

      def validate_cost_object
        if cost_object_id_changed?
          unless cost_object_id.blank? || project.cost_object_ids.include?(cost_object_id)
            errors.add :cost_object, :inclusion
          end
        end
      end

      def material_costs
        if respond_to?(:cost_entries_sum) # column has been eager loaded into result set
          cost_entries_sum.to_f
        else
          ::WorkPackage::MaterialCosts.new(user: User.current).costs_of work_packages: self_and_descendants
        end
      end

      def labor_costs
        if respond_to?(:time_entries_sum) # column has been eager loaded into result set
          time_entries_sum.to_f
        else
          ::WorkPackage::LaborCosts.new(user: User.current).costs_of work_packages: self_and_descendants
        end
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

      def move_cost_entries
        return unless saved_change_to_project_id?
        # TODO: This only works with the global cost_rates
        CostEntry
          .where(work_package_id: id)
          .update_all(project_id: project_id)
      end
    end
  end
end
