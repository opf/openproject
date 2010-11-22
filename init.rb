require 'redmine'

require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'global_roles/roles_controller_patch'
  require_dependency 'global_roles/permission_patch'
  require_dependency 'global_roles/access_control_patch'
  require_dependency 'global_roles/role_patch'
end

Redmine::Plugin.register :redmine_global_roles do
  name 'Redmine Global Roles plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  if RAILS_ENV != "test"
    #patches are loaded after permissions are set
    #hence it is not possible to define an option :public => true
    #we must therefore take the less obvious option to say :require => :global
    #an option ala :public => true would only be possible when the plugin has been moved to core
    require_or_load 'global_roles/permission_patch'

    project_module :user do
      permission :manage_global_roles, {:example => [:say_hello]}, :global => true
    end
  end
end
