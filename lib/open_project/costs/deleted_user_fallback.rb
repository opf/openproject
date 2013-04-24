module OpenProject::Costs
  module DeletedUserFallback
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :user, :deleted_user_fallback
      end
    end

    module InstanceMethods
      def user_with_deleted_user_fallback(force_reload = true)
        associated_user = user_without_deleted_user_fallback(force_reload)

        if associated_user.nil? && read_attribute(:user_id).present?
          associated_user = DeletedUser.first
        end

        associated_user
      end
    end
  end
end
