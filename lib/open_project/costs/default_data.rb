module OpenProject
  module Costs
    module DefaultData
      module_function

      def load!
        add_member_permissions!
      end

      def add_member_permissions!
        role = member_role or raise 'Member role not found'

        role.add_permission! *member_permissions
      end

      def member_role
        Role.find_by name: I18n.t(:default_role_member)
      end

      def member_permissions
        [
          :view_own_hourly_rate,
          :view_cost_rates,
          :log_own_costs,
          :edit_own_cost_entries,
          :view_cost_objects,
          :view_own_cost_entries
        ]
      end
    end
  end
end
