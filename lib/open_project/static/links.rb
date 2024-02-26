#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
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

        delegate :[], to: :links

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
              href: 'https://www.openproject.org/request-quote/',
              label: 'admin.enterprise.get_quote'
            },
            user_guides: {
              href: 'https://www.openproject.org/docs/user-guide/',
              label: 'homescreen.links.user_guides'
            },
            installation_guides: {
              href: 'https://www.openproject.org/docs/installation-and-operations/installation/',
              label: :label_installation_guides
            },
            packager_installation: {
              href: 'https://www.openproject.org/docs/installation-and-operations/installation/packaged/',
              label: 'Packaged installation'
            },
            docker_installation: {
              href: 'https://www.openproject.org/docs/installation-and-operations/installation/docker/',
              label: 'Docker installation'
            },
            manual_installation: {
              href: 'https://www.openproject.org/docs/installation-and-operations/installation/manual/',
              label: 'Manual installation'
            },
            upgrade_guides: {
              href: 'https://www.openproject.org/docs/installation-and-operations/operation/upgrading/',
              label: :label_upgrade_guides
            },
            postgres_migration: {
              href: 'https://www.openproject.org/docs/installation-and-operations/misc/packaged-postgresql-migration/',
              label: :'homescreen.links.postgres_migration'
            },
            postgres_13_upgrade: {
              href: 'https://www.openproject.org/docs/installation-and-operations/misc/migration-to-postgresql13/'
            },
            configuration_guide: {
              href: 'https://www.openproject.org/docs/installation-and-operations/configuration/',
              label: 'links.configuration_guide'
            },
            contact: {
              href: 'https://www.openproject.org/contact/',
              label: 'links.get_in_touch'
            },
            glossary: {
              href: 'https://www.openproject.org/docs/glossary/',
              label: 'homescreen.links.glossary'
            },
            shortcuts: {
              href: 'https://www.openproject.org/docs/user-guide/keyboard-shortcuts-access-keys/',
              label: 'homescreen.links.shortcuts'
            },
            forums: {
              href: 'https://community.openproject.org/projects/openproject/forums',
              label: 'homescreen.links.forums'
            },
            enterprise_support_as_community: {
              href: 'https://www.openproject.org/pricing/#support',
              label: :label_enterprise_support
            },
            enterprise_support: {
              href: 'https://www.openproject.org/docs/enterprise-guide/support/',
              label: :label_enterprise_support
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
              href: 'https://www.openproject.org/docs/release-notes/',
              label: :label_release_notes
            },
            data_privacy: {
              href: 'https://www.openproject.org/legal/privacy/',
              label: :label_privacy_policy
            },
            digital_accessibility: {
              href: 'https://www.openproject.org/de/rechtliches/erklaerung-zur-digitalen-barrierefreiheit/',
              label: :label_digital_accessibility
            },
            report_bug: {
              href: 'https://www.openproject.org/docs/development/report-a-bug/',
              label: :label_report_bug
            },
            roadmap: {
              href: 'https://community.openproject.org/projects/openproject/roadmap',
              label: :label_development_roadmap
            },
            crowdin: {
              href: 'https://www.openproject.org/docs/development/translate-openproject/',
              label: :label_add_edit_translations
            },
            api_docs: {
              href: 'https://www.openproject.org/docs/api/',
              label: :label_api_doc
            },
            text_formatting: {
              href: 'https://www.openproject.org/docs/user-guide/wysiwyg/',
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
              href: 'https://www.rubydoc.info/gems/net-ldap/Net/LDAP#constructor_details'
            },
            origin_mdn_documentation: {
              href: 'https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Origin'
            },
            security_badge_documentation: {
              href: 'https://www.openproject.org/docs/system-admin-guide/information/#security-badge'
            },
            date_format_settings_documentation: {
              href: 'https://www.openproject.org/docs/system-admin-guide/calendars-and-dates/#date-format'
            },
            chargebee: {
              href: 'https://js.chargebee.com/v2/chargebee.js'
            },
            webinar_videos: {
              href: 'https://www.youtube.com/watch?v=un6zCm8_FT4'
            },
            get_started_videos: {
              href: 'https://www.youtube.com/playlist?list=PLGzJ4gG7hPb8WWOWmeXqlfMfhdXReu-RJ'
            },
            openproject_docs: {
              href: 'https://www.openproject.org/docs/'
            },
            contact_us: {
              href: 'https://www.openproject.org/contact/'
            },
            pricing: {
              href: 'https://www.openproject.org/pricing/'
            },
            enterprise_docs: {
              form_configuration: {
                href: 'https://www.openproject.org/docs/system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on'
              },
              attribute_highlighting: {
                href: 'https://www.openproject.org/docs/user-guide/work-packages/work-package-table-configuration/#attribute-highlighting-enterprise-add-on'
              },
              boards: {
                href: 'https://www.openproject.org/docs/user-guide/agile-boards/#action-boards-enterprise-add-on'
              },
              custom_field_projects: {
                href: 'https://www.openproject.org/docs/system-admin-guide/custom-fields/custom-fields-projects/'
              },
              custom_field_multiselect: {
                href: 'https://www.openproject.org/docs/system-admin-guide/custom-fields/#create-a-multi-select-custom-field'
              },
              status_read_only: {
                href: 'https://www.openproject.org/docs/system-admin-guide/manage-work-packages/work-package-status/#create-a-new-work-package-status'
              }
            },
            storage_docs: {
              setup: {
                href: 'https://www.openproject.org/docs/system-admin-guide/integrations/storage/'
              },
              nextcloud_setup: {
                href: 'https://www.openproject.org/docs/system-admin-guide/integrations/nextcloud/'
              },
              one_drive_setup: {
                href: 'https://www.openproject.org/docs/system-admin-guide/integrations/one-drive/'
              },
              one_drive_drive_id_guide: {
                href: 'https://www.openproject.org/docs/system-admin-guide/integrations/one-drive/drive-guide/'
              },
              nextcloud_oauth_application: {
                href: 'https://apps.nextcloud.com/apps/integration_openproject'
              },
              one_drive_oauth_application: {
                href: 'https://portal.azure.com/'
              },
              troubleshooting: {
                href: 'https://www.openproject.org/docs/user-guide/file-management/nextcloud-integration/#possible-errors-and-troubleshooting'
              }
            },
            ical_docs: {
              href: 'https://www.openproject.org/docs/user-guide/calendar/#subscribe-to-a-calendar'
            }
          }
        end
      end
    end
  end
end
