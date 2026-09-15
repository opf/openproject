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
    module Bim
      class ElementLinksController < ::API::V3::BaseController
        before_action :find_element_link, only: %i[show update destroy]
        before_action :authorize_view, only: %i[index show]
        before_action :authorize_manage, only: %i[create update destroy]

        # GET /api/v3/bim/element_links
        # List element links with optional filtering
        def index
          query = build_query_from_params

          links = query.results
          total = query.results.count

          render json: {
            _type: 'Collection',
            total: total,
            count: links.size,
            _embedded: {
              elements: links.map { |link| link_representer(link) }
            },
            _links: pagination_links(query)
          }
        end

        # GET /api/v3/bim/element_links/:id
        # Get a single element link
        def show
          render json: link_representer(@element_link)
        end

        # POST /api/v3/bim/element_links
        # Create a new element link
        def create
          link = ::Bim::ElementLink.new(create_params)
          link.user = current_user

          if link.save
            render json: link_representer(link), status: :created
          else
            render json: error_response(link.errors), status: :unprocessable_entity
          end
        end

        # PATCH /api/v3/bim/element_links/:id
        # Update an element link
        def update
          if @element_link.update(update_params)
            render json: link_representer(@element_link)
          else
            render json: error_response(@element_link.errors), status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/element_links/:id
        # Delete an element link
        def destroy
          if @element_link.destroy
            head :no_content
          else
            render json: error_response(@element_link.errors), status: :unprocessable_entity
          end
        end

        private

        def find_element_link
          @element_link = ::Bim::ElementLink.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: error_response('Element link not found'), status: :not_found
        end

        def authorize_view
          authorize_any(%i[view_ifc_models view_work_packages], global: true)
        end

        def authorize_manage
          authorize(:manage_ifc_models, global: true)
        end

        def create_params
          params.require(:element_link).permit(
            :work_package_id,
            :ifc_model_id,
            :element_id,
            :relationship_type,
            :template_id,
            element_properties: {}
          )
        end

        def update_params
          params.require(:element_link).permit(
            :relationship_type,
            :status,
            element_properties: {}
          )
        end

        def build_query_from_params
          query = ::Bim::ElementLink.all

          # Filter by work package
          if params[:work_package_id].present?
            query = query.where(work_package_id: params[:work_package_id])
          end

          # Filter by IFC model
          if params[:ifc_model_id].present?
            query = query.where(ifc_model_id: params[:ifc_model_id])
          end

          # Filter by element ID
          if params[:element_id].present?
            query = query.where(element_id: params[:element_id])
          end

          # Filter by relationship type
          if params[:relationship_type].present?
            query = query.where(relationship_type: params[:relationship_type])
          end

          # Filter by status
          if params[:status].present?
            query = query.where(status: params[:status])
          end

          # Filter by template
          if params[:template_id].present?
            query = query.where(template_id: params[:template_id])
          end

          # Pagination
          page = params[:page].to_i.positive? ? params[:page].to_i : 1
          per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 20
          per_page = [per_page, 100].min # Max 100 per page

          PaginatedQuery.new(query, page: page, per_page: per_page)
        end

        def link_representer(link)
          {
            _type: 'ElementLink',
            id: link.id,
            element_id: link.element_id,
            relationship_type: link.relationship_type,
            status: link.status,
            element_properties: link.element_properties,
            created_at: link.created_at.iso8601,
            updated_at: link.updated_at.iso8601,
            _links: {
              self: { href: api_v3_bim_element_link_path(link) },
              work_package: { href: api_v3_work_package_path(link.work_package_id) },
              ifc_model: { href: api_v3_bim_ifc_model_path(link.ifc_model_id) },
              template: link.template_id ? { href: api_v3_bim_link_template_path(link.template_id) } : nil,
              user: link.user_id ? { href: api_v3_user_path(link.user_id) } : nil
            }.compact
          }
        end

        def pagination_links(query)
          {
            self: { href: request.original_url },
            next: query.next_page? ? { href: next_page_url(query) } : nil,
            previous: query.previous_page? ? { href: previous_page_url(query) } : nil
          }.compact
        end

        def next_page_url(query)
          url_for(params.merge(page: query.current_page + 1))
        end

        def previous_page_url(query)
          url_for(params.merge(page: query.current_page - 1))
        end

        def error_response(errors)
          {
            _type: 'Error',
            errorIdentifier: 'urn:openproject-org:api:v3:errors:InvalidRequestBody',
            message: errors.is_a?(String) ? errors : errors.full_messages.join(', ')
          }
        end

        # Simple pagination wrapper
        class PaginatedQuery
          attr_reader :query, :page, :per_page

          def initialize(query, page:, per_page:)
            @query = query
            @page = page
            @per_page = per_page
          end

          def results
            query.limit(per_page).offset((page - 1) * per_page)
          end

          def current_page
            page
          end

          def next_page?
            query.count > page * per_page
          end

          def previous_page?
            page > 1
          end
        end
      end
    end
  end
end
