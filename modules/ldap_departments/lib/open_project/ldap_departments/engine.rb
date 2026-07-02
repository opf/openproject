# frozen_string_literal: true

module OpenProject::LdapDepartments
  class Engine < ::Rails::Engine
    engine_name :openproject_ldap_departments

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-ldap_departments",
             author_url: "https://github.com/opf/openproject",
             bundled: true,
             settings: {
               default: {}
             } do
      menu :admin_menu,
           :plugin_ldap_departments,
           { controller: "/ldap_departments/synchronized_trees", action: :index },
           parent: :authentication,
           after: :plugin_ldap_groups,
           caption: ->(*) { I18n.t("ldap_departments.label_menu_item") },
           enterprise_feature: "ldap_groups"
    end

    add_cron_jobs do
      {
        "LdapDepartments::SynchronizationJob": {
          cron: "*/30 * * * *", # Run every 30 minutes
          class: LdapDepartments::SynchronizationJob.name
        }
      }
    end

    patches %i[LdapAuthSource Group User]
  end
end
