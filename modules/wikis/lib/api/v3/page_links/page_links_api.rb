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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module PageLinks
      class PageLinksAPI < OpenProjectAPI
        helpers do
          def enrich_models_with_wiki_metadata(relation)
            Wikis::PageLinkMetadataService.new(relation).call
          end
        end

        resources :wiki_page_links do
          post &::API::V3::PageLinks::CreateEndpoint.new(
            model: ::Wikis::RelationPageLink,
            instance_generator: ->(*) { Wikis::RelationPageLink.new },
            parse_representer: RelationPageLinkRepresenter,
            parse_service: ParsePageLinkParamsService,
            process_service: ::Wikis::RelationPageLinks::CreateService,
            process_contract: ::Wikis::RelationPageLinks::CreateContract,
            render_representer: PageLinkCollectionRepresenter
          ).mount

          get do
            query = ParamsToQueryService.new(
              ::Wikis::PageLink,
              current_user,
              query_class: ::Queries::Wikis::PageLinks::PageLinkQuery
            ).call(params)

            unless query.valid?
              message = I18n.t("api_v3.errors.missing_or_malformed_parameter", parameter: "filters")
              raise ::API::Errors::InvalidQuery.new(message)
            end

            relation = query.results.where(linkable: Authorization.work_packages(:view_work_packages, current_user))

            PageLinkCollectionRepresenter.new(
              enrich_models_with_wiki_metadata(relation).result,
              per_page: params[:pageSize],
              self_link: api_v3_paths.wiki_page_links,
              current_user:
            )
          end

          route_param :wiki_page_link_id, type: Integer, description: "Wiki Page Link ID" do
            after_validation do
              @relation_page_link = Wikis::RelationPageLink.find(params[:wiki_page_link_id])

              unless authorize_in_project(:manage_wiki_page_links, project: @relation_page_link.linkable.project)
                raise ::API::Errors::NotFound.new
              end
            end

            delete &API::Utilities::Endpoints::Delete.new(
              model: Wikis::RelationPageLink,
              process_service: Wikis::RelationPageLinks::DeleteService
            ).mount
          end
        end
      end
    end
  end
end
