module OpenProject::Costs::Patches::ApplicationControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :authorize, :for_user
    end
  end

  module InstanceMethods
    # Authorize the user for the requested action
    def authorize_with_for_user(ctrl = params[:controller], action = params[:action], global = false, for_user=@user)
      allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project || @projects, :global => global, :for => for_user)
      allowed ? true : deny_access
    end
  end
end
