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
    module CustomFields
      module Hierarchy
        class ItemAPI < ::API::OpenProjectAPI
          resource :custom_field_items do
            route_param :id, type: Integer, desc: "Custom Field Item ID" do
              after_validation do
                authorize_logged_in

                @custom_field_item = CustomField::Hierarchy::Item.find(params[:id])

                # Only for checking the authorization.
                CustomField.visible.find(@custom_field_item.root.custom_field_id)
              end

              get &::API::V3::Utilities::Endpoints::Show
                     .new(model: CustomField::Hierarchy::Item,
                          render_representer: HierarchyItemRepresenter,
                          instance_generator: ->(*) do
                            HierarchicalItemAggregate.new(item: @custom_field_item, depth: @custom_field_item.depth - 1)
                          end)
                     .mount

              mount ItemBranchAPI
            end
          end
        end
      end
    end
  end
end
