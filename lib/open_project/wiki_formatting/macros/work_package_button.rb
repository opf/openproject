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
  module WikiFormatting
    module Macros
      module WorkPackageButton
        Redmine::WikiFormatting::Macros.register do
          desc 'Inserts a link or button to the create form of a work package'
          macro :create_work_package_link do |_obj, args, options|
            project = @project || options[:project]
            if project.nil?
              raise I18n.t('macros.create_work_package_link.errors.no_project_context')
            end

            type_name = args.shift
            class_name = args.shift == 'button' ? 'button' : nil
            if type_name.present?
              type = project.types.find_by(name: type_name)
              if type.nil?
                raise I18n.t(
                  'macros.create_work_package_link.errors.invalid_type',
                  type: type_name,
                  project: project.name
                )
              end

              link_to I18n.t('macros.create_work_package_link.link_name_type', type_name: type_name),
                      new_project_work_packages_path(project_id: project.identifier, type: type.id),
                      class: class_name
            else
              link_to I18n.t('macros.create_work_package_link.link_name'),
                      new_project_work_packages_path(project_id: project.identifier),
                      class: class_name
            end
          end
        end
      end
    end
  end
end
