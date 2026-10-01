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
              def legacy_list_item(id)
                item = CustomField::Hierarchy::Item.includes(parent: :custom_field).find_by(legacy_option_id: id)
                raise API::Errors::NotFound unless item

                item
              end

              def authorize_custom_option_visibility(custom_field)
                case custom_field
                when WorkPackageCustomField
                  authorized_work_package_option(custom_field)
                when ProjectCustomField
                  authorized_project_custom_option(custom_field)
                when TimeEntryCustomField
                  authorize_in_any_work_package(:log_own_time) do
                    authorize_in_any_project(:log_time) do
                      raise API::Errors::NotFound
                    end
                  end
                when UserCustomField
                  authorized_user_custom_option(custom_field)
                when GroupCustomField
                  authorized_group_custom_option(custom_field)
                else
                  raise API::Errors::NotFound
                end
              end

              def authorized_work_package_option(custom_field)
                allowed = Project
                  .with_visible_work_packages(current_user)
                  .joins(:work_package_custom_fields)
                  .exists?(custom_fields: { id: custom_field.id })

                unless allowed
                  raise API::Errors::NotFound
                end
              end

              def authorized_project_custom_option(custom_field)
                unless Project
                  .visible(current_user)
                  .joins(:project_custom_field_project_mappings)
                  .exists?(project_custom_field_project_mappings: { custom_field_id: custom_field.id })
                  raise API::Errors::NotFound
                end
              end

              def authorized_user_custom_option(custom_field)
                unless UserCustomField
                  .visible(current_user)
                  .exists?(id: custom_field.id)
                  raise API::Errors::NotFound
                end
              end

              def authorized_group_custom_option(custom_field)
                unless GroupCustomField
                  .visible(current_user)
                  .exists?(id: custom_field.id)
                  raise API::Errors::NotFound
                end
              end
            end

            get do
              item = legacy_list_item(params[:id])

              authorize_custom_option_visibility(item.parent.custom_field)

              header "Deprecation", "true"
              header "Link", "<#{api_v3_paths.custom_field_item(item.id)}>; rel=\"successor-version\""

              {
                _type: "CustomOption",
                id: item.legacy_option_id,
                value: item.label,
                _links: {
                  self: {
                    href: api_v3_paths.custom_option(item.legacy_option_id),
                    title: item.label
                  }
                }
              }
            end
          end
        end
      end
    end
  end
end
