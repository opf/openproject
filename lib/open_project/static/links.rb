#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
            user_guides: {
              href: 'https://www.openproject.org/help/',
              label: 'homescreen.links.user_guides'
            },
            configuration_guide: {
              href: 'https://www.openproject.org/operations/configuration/',
              label: 'links.configuration_guide'
            },
            glossary: {
              href: 'https://www.openproject.org/help/glossary/',
              label: 'homescreen.links.glossary'
            },
            shortcuts: {
              href: 'https://www.openproject.org/help/keyboard-shortcuts-access-keys/',
              label: 'homescreen.links.shortcuts'
            },
            boards: {
              href: 'https://community.openproject.com/projects/openproject/boards',
              label: 'homescreen.links.boards'
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
              href: 'https://www.openproject.org/release-notes/',
              label: :label_release_notes
            },
            data_privacy: {
              href: 'https://www.openproject.org/data-privacy-and-security/',
              label: :label_privacy_policy
            },
            report_bug: {
              href: 'https://www.openproject.org/development/report-a-bug/',
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
              href: 'https://www.openproject.org/api',
              label: :label_api_documentation
            },
            text_formatting: {
              href: 'https://www.openproject.org/help/wiki/',
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
              href: 'https://github.com/opf/openproject/blob/dev/docs/configuration/configuration.md#security-badge'
            }
          }
        end
      end
    end
  end
end
