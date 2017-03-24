#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module Static
    module Links
      class << self

        def help_link_overridden?
          OpenProject::Configuration.force_help_link.present?
        end

        def help_link
          OpenProject::Configuration.force_help_link.presence || links[:user_guides]
        end

        def links
          {
            upsale: {
              href: 'https://www.openproject.org/enterprise-edition',
              label: 'homescreen.links.upgrade_enterprise_edition'
            },
            user_guides: {
              href: 'https://www.openproject.org/help/',
              label: 'homescreen.links.user_guides'
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
              href: 'https://www.openproject.org/enterprise-edition/',
              label: :label_professional_support
            },
            blog: {
              href: 'https://www.openproject.org/blog',
              label: 'homescreen.links.blog'
            },
            release_notes: {
              href: 'https://www.openproject.org/release-notes/',
              label: :label_release_notes
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
          }
        end
      end
    end
  end
end
