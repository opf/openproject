# frozen_string_literal: true

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

require "api/v3/labels/label_collection_representer"
require "api/v3/labels/label_payload_representer"
require "api/v3/labels/label_representer"

module API
  module V3
    module Labels
      class LabelsAPI < ::API::OpenProjectAPI
        resources :labels do
          after_validation do
            raise API::Errors::NotFound unless OpenProject::FeatureDecisions.work_package_labels_active?

            authorize_in_any_work_package(:view_work_packages)
          end

          get &::API::V3::Utilities::Endpoints::Index
                 .new(model: Label)
                 .mount

          post do
            authorize_in_any_project(:edit_work_packages)

            attributes = ::API::V3::ParseResourceParamsService
                           .new(current_user, model: Label)
                           .call(request_body)
                           .result

            call = ::Labels::FindOrCreateService.new(user: current_user).call(name: attributes[:name])

            if call.success?
              status call.result.previously_new_record? ? :created : :ok
              LabelRepresenter.create(call.result, current_user:, embed_links: true)
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end
          end

          route_param :id, type: Integer, desc: "Label ID" do
            after_validation do
              @label = Label.find(params[:id])
            end

            get do
              LabelRepresenter.new(@label, current_user:)
            end
          end
        end
      end
    end
  end
end
