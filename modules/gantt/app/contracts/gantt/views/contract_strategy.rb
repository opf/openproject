module ::Gantt
  module Views
    class ContractStrategy < ::BaseContract
      validate :manageable

      private

      def manageable
        return if model.query.blank?

        errors.add(:base, :error_unauthorized) unless query_permissions?
      end

      def query_permissions?
        # The visibility i.e. whether a private query belongs to the user is checked via the
        # query_visible? method.
        (model.query.public && user_allowed_on_query?(:manage_public_queries)) ||
          (!model.query.public && user_allowed_on_query?(:save_queries))
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
