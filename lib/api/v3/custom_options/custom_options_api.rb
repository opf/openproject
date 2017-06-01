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
    module CustomOptions
      class CustomOptionsAPI < ::API::OpenProjectAPI
        resources :custom_options do
          namespace ':id' do
            params do
              requires :id, type: Integer
            end

            helpers do
              def authorize_view_in_activated_project(custom_option)
                allowed = Project
                          .allowed_to(current_user, :view_work_packages)
                          .joins(:work_package_custom_fields)
                          .where(custom_fields: { id: custom_option.custom_field_id })
                          .exists?

                unless allowed
                  raise API::Errors::NotFound
                end
              end
            end

            get do
              co = CustomOption.find(params[:id])

              authorize_view_in_activated_project(co)

              CustomOptionRepresenter.new(co, current_user: current_user)
            end
          end
        end
      end
    end
  end
end
