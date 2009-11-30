module ApplicationControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unless instance_methods.include? "authorize_without_for_user"
        alias_method_chain :authorize, :for_user
      end
    end
  end

  module InstanceMethods
    # Authorize the user for the requested action
    def authorize_with_for_user(ctrl = params[:controller], action = params[:action], global = false, for_user=@user)
      allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project, :global => global, :for => for_user)
      allowed ? true : deny_access
    end
  end
end







