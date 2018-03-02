module OpenProject::LdapGroups
  class Engine < ::Rails::Engine
    engine_name :openproject_ldap_groups

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-ldap_groups',
             author_url: 'https://github.com/opf/openproject-ldap_groups',
             settings: {
               default: {
                 group_base: nil
               }
             } do
      menu :admin_menu,
           :plugin_ldap_groups,
           { controller: '/ldap_groups/synchronized_groups', action: :index },
           parent: :ldap_authentication,
           caption: ->(*) { I18n.t('ldap_groups.label_menu_item') }
    end

    patches %i[AuthSource Group]
  end
end
