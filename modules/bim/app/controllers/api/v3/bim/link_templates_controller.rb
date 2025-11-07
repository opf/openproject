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
      class LinkTemplatesController < ::API::V3::BaseController
        before_action :find_template, only: %i[show update destroy clone statistics]
        before_action :authorize_view, only: %i[index show statistics]
        before_action :authorize_manage, only: %i[create update destroy clone]

        # GET /api/v3/bim/link_templates
        # List link templates with optional filtering
        def index
          templates = build_query_from_params

          render json: {
            _type: 'Collection',
            total: templates.count,
            count: templates.size,
            _embedded: {
              elements: templates.map { |template| template_representer(template) }
            }
          }
        end

        # GET /api/v3/bim/link_templates/:id
        # Get a single link template
        def show
          render json: template_representer(@template, detailed: true)
        end

        # POST /api/v3/bim/link_templates
        # Create a new link template
        def create
          template = ::Bim::LinkTemplate.new(create_params)
          template.author = current_user

          if template.save
            render json: template_representer(template, detailed: true), status: :created
          else
            render json: error_response(template.errors), status: :unprocessable_entity
          end
        end

        # PATCH /api/v3/bim/link_templates/:id
        # Update a link template
        def update
          if @template.update(update_params)
            render json: template_representer(@template, detailed: true)
          else
            render json: error_response(@template.errors), status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/link_templates/:id
        # Delete a link template
        def destroy
          if @template.destroy
            head :no_content
          else
            render json: error_response(@template.errors), status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/link_templates/:id/clone
        # Clone a template with modifications
        def clone
          cloned = @template.clone_template(
            new_name: params[:new_name],
            modifications: clone_modifications_params
          )

          if cloned.save
            render json: template_representer(cloned, detailed: true), status: :created
          else
            render json: error_response(cloned.errors), status: :unprocessable_entity
          end
        end

        # GET /api/v3/bim/link_templates/:id/statistics
        # Get usage statistics for a template
        def statistics
          stats = @template.statistics

          render json: {
            _type: 'TemplateStatistics',
            template_id: @template.id,
            total_links: stats[:total_links],
            active_links: stats[:active_links],
            completed_links: stats[:completed_links],
            archived_links: stats[:archived_links],
            work_packages: stats[:work_packages],
            ifc_models: stats[:ifc_models],
            _links: {
              template: { href: api_v3_bim_link_template_path(@template) }
            }
          }
        end

        private

        def find_template
          @template = ::Bim::LinkTemplate.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: error_response('Template not found'), status: :not_found
        end

        def authorize_view
          authorize_any(%i[view_ifc_models view_work_packages], global: true)
        end

        def authorize_manage
          authorize(:manage_ifc_models, global: true)
        end

        def build_query_from_params
          query = ::Bim::LinkTemplate.all

          # Filter by project
          if params[:project_id].present?
            query = query.for_project(params[:project_id])
          end

          # Filter by relationship type
          if params[:relationship_type].present?
            query = query.by_relationship(params[:relationship_type])
          end

          # Filter by public/private
          if params[:public].present?
            query = params[:public] == 'true' ? query.public_templates : query.private_templates
          end

          # Filter by auto-apply
          if params[:auto_apply].present?
            query = query.auto_apply_templates if params[:auto_apply] == 'true'
          end

          query.order(created_at: :desc)
        end

        def create_params
          params.require(:link_template).permit(
            :name,
            :description,
            :relationship_type,
            :work_package_type,
            :auto_apply,
            :public,
            :project_id,
            element_filters: {},
            template_data: {}
          )
        end

        def update_params
          params.require(:link_template).permit(
            :name,
            :description,
            :relationship_type,
            :work_package_type,
            :auto_apply,
            :public,
            element_filters: {},
            template_data: {}
          )
        end

        def clone_modifications_params
          return {} unless params[:modifications].present?

          params.require(:modifications).permit(
            :description,
            :relationship_type,
            :work_package_type,
            :auto_apply,
            :public,
            :project_id,
            element_filters: {},
            template_data: {}
          ).to_h
        end

        def template_representer(template, detailed: false)
          base = {
            _type: 'LinkTemplate',
            id: template.id,
            name: template.name,
            description: template.description,
            relationship_type: template.relationship_type,
            auto_apply: template.auto_apply,
            public: template.public,
            created_at: template.created_at.iso8601,
            updated_at: template.updated_at.iso8601,
            _links: {
              self: { href: api_v3_bim_link_template_path(template) },
              author: { href: api_v3_user_path(template.author_id) },
              project: template.project_id ? { href: api_v3_project_path(template.project_id) } : nil,
              statistics: { href: api_v3_bim_link_template_statistics_path(template) },
              clone: { href: api_v3_bim_link_template_clone_path(template), method: :post }
            }.compact
          }

          if detailed
            base.merge!(
              work_package_type: template.work_package_type,
              element_filters: template.element_filters,
              template_data: template.template_data
            )
          end

          base
        end

        def error_response(errors)
          {
            _type: 'Error',
            errorIdentifier: 'urn:openproject-org:api:v3:errors:InvalidRequestBody',
            message: errors.is_a?(String) ? errors : errors.full_messages.join(', ')
          }
        end
      end
    end
  end
end
