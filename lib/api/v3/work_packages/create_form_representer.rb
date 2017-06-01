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

module API
  module V3
    module WorkPackages
      class CreateFormRepresenter < FormRepresenter
        link :self do
          {
            href: api_v3_paths.create_work_package_form,
            method: :post
          }
        end

        link :validate do
          {
            href: api_v3_paths.create_work_package_form,
            method: :post
          }
        end

        link :previewMarkup do
          context = api_v3_paths.project(represented.project_id) if represented.project_id
          {
            href: api_v3_paths.render_markup(link: context),
            method: :post
          }
        end

        link :commit do
          if represented.project &&
             current_user.allowed_to?(:edit_work_packages,
                                      represented.project) &&
             @errors.empty?
            {
              href: api_v3_paths.work_packages,
              method: :post
            }
          end
        end

        link :customFields do
          if represented.project && (
              current_user.try(:admin?) ||
              current_user_allowed_to(:edit_project,
                                      context: represented.project))
            {
              href: settings_project_path(represented.project.identifier,
                                          tab: 'custom_fields'),
              type: 'text/html',
              title: I18n.t('label_custom_field_plural')
            }
          end
        end

        link :configureForm do
          if current_user.admin? &&
             represented.type_id &&
             represented.type_id != 0
            {
              href: edit_type_path(represented.type_id, tab: 'form_configuration'),
              type: 'text/html',
              title: "Configure form"
            }
          end
        end
      end
    end
  end
end
