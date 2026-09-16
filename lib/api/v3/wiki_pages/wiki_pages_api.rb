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
    module WikiPages
      class WikiPagesAPI < ::API::OpenProjectAPI
        resources :wiki_pages do
          get &::API::V3::Utilities::Endpoints::Index.new(
            model: WikiPage,
            scope: -> { WikiPage.visible(current_user) }
          ).mount

          post &::API::V3::Utilities::Endpoints::Create.new(model: WikiPage).mount

          mount ::API::V3::WikiPages::Schemas::WikiPageSchemaAPI
          mount ::API::V3::WikiPages::CreateFormAPI

          helpers do
            def wiki_page
              WikiPage.visible(current_user).find(params[:id])
            end

            def delete_todo
              params[:todo].presence || env.dig("api.request.body", "todo")
            end

            def delete_reassign_to_id
              return params[:reassign_to_id] if params[:reassign_to_id].present?

              href = env.dig("api.request.body", "_links", "reassignTo", "href") ||
                     env.dig("api.request.body", "reassignTo", "href")
              return if href.blank?

              ::API::Utilities::ResourceLinkParser.parse_id(
                href,
                property: :reassignTo,
                expected_version: "3",
                expected_namespace: "wiki_pages"
              )
            end
          end

          route_param :id, type: Integer, desc: "Wiki page ID" do
            after_validation do
              @wiki_page = wiki_page
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: WikiPage).mount

            patch &::API::V3::Utilities::Endpoints::Update.new(model: WikiPage).mount

            params do
              optional :todo, type: String, values: %w[nullify destroy reassign]
              optional :reassign_to_id, type: Integer
            end
            delete do
              call = ::WikiPages::DeleteService
                .new(user: current_user, model: @wiki_page)
                .call(todo: delete_todo, reassign_to_id: delete_reassign_to_id)

              if call.success?
                status :no_content
              else
                fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
              end
            end

            mount ::API::V3::WikiPages::UpdateFormAPI
            mount ::API::V3::WikiPages::ActivitiesByWikiPageAPI
            mount ::API::V3::Attachments::AttachmentsByWikiPageAPI
          end
        end
      end
    end
  end
end
