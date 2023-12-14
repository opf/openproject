module ::Calendar
  module Views
    class ContractStrategy < ::BaseContract
      validate :manageable

      private

      def manageable
        return if model.query.blank?

        errors.add(:base, :error_unauthorized) unless query_permissions?
      end

      def query_permissions?
        user_allowed_on_query?(:view_calendar)
      end

      def user_allowed_on_query?(permission)
        if model.query.project
          user.allowed_in_project?(permission, model.query.project)
        else
          user.allowed_in_any_project?(permission)
        end
      end
    end
  end
end
