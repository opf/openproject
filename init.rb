require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'global_roles/roles_controller_patch'
  require_dependency 'global_roles/users_controller_patch'

  require_dependency 'global_roles/permission_patch'
  require_dependency 'global_roles/access_control_patch'

  require_dependency 'global_roles/role_patch'
  require_dependency 'global_roles/principal_patch'

  require_dependency 'global_roles/users_helper_patch'
  require_dependency 'global_roles/roles_helper_patch'
end

Redmine::Plugin.register :redmine_global_roles do
  name 'Global Roles plugin'
  author 'Jens Ulferts @ finnlabs'
  description 'Adds global, meaning non project bound, roles. Create Project becomes a global role.'
  version '0.1.0'

  if RAILS_ENV != "test"
    require_or_load 'global_roles/permission_patch'
    project_module :user do
      permission :manage_global_roles, {:example => [:say_hello]}, :global => true
    end
    Redmine::AccessControl.permission(:add_project).global = true
  else
    Redmine::AccessControl.permission(:add_project).instance_eval do
      @global = true
    end
  end
end

