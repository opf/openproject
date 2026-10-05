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

module API
  module V3
    module Whiteboards
      class WhiteboardsAPI < ::API::OpenProjectAPI
        resources :whiteboards do
          after_validation do
            raise API::Errors::NotFound unless OpenProject::FeatureDecisions.whiteboards_active?
          end

          route_param :id, type: Integer, desc: "Whiteboard ID" do
            helpers do
              def whiteboard
                @whiteboard ||= Whiteboard.visible(current_user).find(params[:id])
              end

              def represent(whiteboard)
                WhiteboardRepresenter.new(whiteboard, current_user:, embed_links: true)
              end
            end

            get do
              represent(whiteboard)
            end

            patch do
              attributes = JSON.parse(request.body.read).slice("content_binary", "scene", "searchable_text")

              result = ::Whiteboards::UpdateService
                .new(user: current_user, model: whiteboard)
                .call(attributes)

              if result.success?
                represent(whiteboard)
              else
                fail ::API::Errors::ErrorBase.create_and_merge_errors(whiteboard.errors)
              end
            end
          end
        end
      end
    end
  end
end
