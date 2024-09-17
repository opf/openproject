#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module API
  module V3
    module CustomOptions
      class CustomOptionsAPI < ::API::OpenProjectAPI
        resources :custom_options do
          namespace ":id" do
            params do
              requires :id, type: Integer
            end

            helpers do
              def authorize_custom_option_visibility(custom_option)
                case custom_option.custom_field
                when WorkPackageCustomField
                  authorized_work_package_option(custom_option)
                when ProjectCustomField
                  authorize_in_any_project(%i[view_project]) { raise API::Errors::NotFound }
                when TimeEntryCustomField
                  authorize_in_any_work_package(:log_own_time) do
                    authorize_in_any_project(:log_time) do
                      raise API::Errors::NotFound
                    end
                  end
                when UserCustomField, GroupCustomField
                  true
                else
                  raise API::Errors::NotFound
                end
              end

              def authorized_work_package_option(custom_option)
                allowed = Project
                  .with_visible_work_packages(current_user)
                  .joins(:work_package_custom_fields)
                  .exists?(custom_fields: { id: custom_option.custom_field_id })

                unless allowed
                  raise API::Errors::NotFound
                end
              end
            end

            get do
              co = CustomOption.find(params[:id])

              authorize_custom_option_visibility(co)

              CustomOptionRepresenter.new(co, current_user:)
            end
          end
        end
      end
    end
  end
end
