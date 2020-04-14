#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module Static
    module Links
      class << self
        def help_link_overridden?
          OpenProject::Configuration.force_help_link.present?
        end

        def help_link
          OpenProject::Configuration.force_help_link.presence || static_links[:user_guides]
        end

        def [](name)
          links[name]
        end

        def links
          @links ||= static_links.merge(dynamic_links)
        end

        def has?(name)
          @links.key? name
        end

        private

        def dynamic_links
          dynamic = {
            help: {
              href: help_link,
              label: 'top_menu.help_and_support'
            }
          }

          if impressum_link = OpenProject::Configuration.impressum_link
            dynamic[:impressum] = {
              href: impressum_link,
              label: :label_impressum
            }
          end

          dynamic
        end

        def static_links
          {
            upsale: {
              href: 'https://www.openproject.org/enterprise-edition',
              label: 'homescreen.links.upgrade_enterprise_edition'
            },
            upsale_benefits_features: {
              href: 'https://www.openproject.org/enterprise-edition/#premium-features',
              label: 'noscript_learn_more'
            },
            upsale_benefits_installation: {
              href: 'https://www.openproject.org/enterprise-edition/#installation',
              label: 'noscript_learn_more'
            },
            upsale_benefits_security: {
              href: 'https://www.openproject.org/enterprise-edition/#security-features',
              label: 'noscript_learn_more'
            },
            upsale_benefits_support: {
              href: 'https://www.openproject.org/enterprise-edition/#professional-support',
              label: 'noscript_learn_more'
            },
            upsale_get_quote: {
              href: 'https://www.openproject.org/upgrade-enterprise-edition/',
              label: 'admin.enterprise.get_quote'
            },
            user_guides: {
              href: 'https://docs.openproject.org/user-guide/',
              label: 'homescreen.links.user_guides'
            },
            upgrade_guides: {
              href: 'https://www.openproject.org/operations/upgrading/',
              label: :label_upgrade_guides
            },
            postgres_migration: {
              href: 'https://www.openproject.org/operations/migration-guides/migrating-packaged-openproject-database-postgresql/',
              label: :'homescreen.links.postgres_migration'
            },
            configuration_guide: {
              href: 'https://www.openproject.org/operations/configuration/',
              label: 'links.configuration_guide'
            },
            contact: {
              href: 'https://www.openproject.org/contact-us/',
              label: 'links.get_in_touch'
            },
            glossary: {
              href: 'https://www.openproject.org/help/glossary/',
              label: 'homescreen.links.glossary'
            },
            shortcuts: {
              href: 'https://docs.openproject.org/user-guide/keyboard-shortcuts-access-keys/',
              label: 'homescreen.links.shortcuts'
            },
            forums: {
              href: 'https://community.openproject.com/projects/openproject/forums',
              label: 'homescreen.links.forums'
            },
            professional_support: {
              href: 'https://www.openproject.org/pricing/#support',
              label: :label_professional_support
            },
            website: {
              href: 'https://www.openproject.org',
              label: 'label_openproject_website'
            },
            newsletter: {
              href: 'https://www.openproject.org/newsletter',
              label: 'homescreen.links.newsletter'
            },
            blog: {
              href: 'https://www.openproject.org/blog',
              label: 'homescreen.links.blog'
            },
            release_notes: {
              href: 'https://docs.openproject.org/release-notes/',
              label: :label_release_notes
            },
            data_privacy: {
              href: 'https://www.openproject.org/data-privacy-and-security/',
              label: :label_privacy_policy
            },
            report_bug: {
              href: 'https://docs.openproject.org/development/report-a-bug/',
              label: :label_report_bug
            },
            roadmap: {
              href: 'https://community.openproject.org/projects/openproject/roadmap',
              label: :label_development_roadmap
            },
            crowdin: {
              href: 'https://crowdin.com/projects/opf',
              label: :label_add_edit_translations
            },
            api_docs: {
              href: 'https://docs.openproject.org/api',
              label: :label_api_documentation
            },
            text_formatting: {
              href: 'https://docs.openproject.org/user-guide/wiki/',
              label: :setting_text_formatting
            },
            oauth_authorization_code_flow: {
              href: 'https://oauth.net/2/grant-types/authorization-code/',
              label: 'oauth.flows.authorization_code'
            },
            client_credentials_code_flow: {
              href: 'https://oauth.net/2/grant-types/client-credentials/',
              label: 'oauth.flows.client_credentials'
            },
            ldap_encryption_documentation: {
              href: 'https://www.rubydoc.info/gems/net-ldap/Net/LDAP#constructor_details',
            },
            security_badge_documentation: {
              href: 'https://docs.openproject.org/system-admin-guide/information/#security-badge'
            },
            chargebee: {
              href: 'https://js.chargebee.com/v2/chargebee.js',
            }
          }
        end
      end
    end
  end
end
