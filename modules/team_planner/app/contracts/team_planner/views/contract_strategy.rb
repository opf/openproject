module ::TeamPlanner
  module Views
    class ContractStrategy < ::BaseContract
      validate :manageable

      private

      def manageable
        return if model.query.blank?

        errors.add(:base, :error_unauthorized) unless query_permissions?
      end

      def query_permissions?
        # TODO: This currently does not differentiate between public and private queries since it isn't specified yet.
        user_allowed_on_query?(:manage_team_planner)
      end

      def user_allowed_on_query?(permission)
        user.allowed_to?(permission, model.query.project, global: model.query.project.nil?)
      end
    end
  end
end
