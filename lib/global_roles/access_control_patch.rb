module GlobalRoles
  module AccessControlPatch
    def self.included(base)
      base.class_eval do
        def self.global_permissions
          @global_permissions ||= @permissions.select {|p| p.global?}
        end
      end
    end
  end
end

Redmine::AccessControl.send(:include, GlobalRoles::AccessControlPatch)