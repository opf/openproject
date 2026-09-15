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
      module ElementLinks
        class BulkOperationsController < ::API::V3::BaseController
          before_action :authorize_manage
          before_action :rate_limit_check, only: %i[bulk_create create_work_packages]

          # POST /api/v3/bim/element_links/bulk_create
          # Create multiple links at once
          def bulk_create
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            result = service.create_bulk_links(
              work_package: find_work_package,
              ifc_model: find_ifc_model,
              element_ids: params[:element_ids],
              relationship_type: params[:relationship_type],
              template: params[:template_id] ? find_template : nil
            )

            if result.success?
              render json: bulk_response(result.result), status: :created
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          # PATCH /api/v3/bim/element_links/bulk_update
          # Update multiple links at once
          def bulk_update
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            result = service.update_bulk_links(
              link_ids: params[:link_ids],
              attributes: update_attributes_params
            )

            if result.success?
              render json: bulk_response(result.result)
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          # POST /api/v3/bim/element_links/bulk_delete
          # Delete multiple links at once
          def bulk_delete
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            result = service.delete_bulk_links(
              link_ids: params[:link_ids],
              soft_delete: params.fetch(:soft_delete, true)
            )

            if result.success?
              render json: result.result
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          # POST /api/v3/bim/element_links/bulk_status_change
          # Change status for multiple links
          def bulk_status_change
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            result = service.bulk_status_change(
              link_ids: params[:link_ids],
              new_status: params[:new_status]
            )

            if result.success?
              render json: result.result
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          # POST /api/v3/bim/element_links/apply_template
          # Apply a template to create links
          def apply_template
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            result = service.apply_template(
              work_package: find_work_package,
              ifc_model: find_ifc_model,
              template: find_template,
              dry_run: params.fetch(:dry_run, false)
            )

            if result.success?
              if params[:dry_run]
                render json: {
                  matching_elements: result.result[:matching_elements],
                  count: result.result[:count]
                }
              else
                render json: bulk_response(result.result), status: :created
              end
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          # POST /api/v3/bim/element_links/create_work_packages
          # Create work packages from element selections
          def create_work_packages
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            result = service.create_work_packages_from_elements(
              ifc_model: find_ifc_model,
              element_ids: params[:element_ids],
              work_package_template: work_package_template_params,
              relationship_type: params[:relationship_type],
              grouping_strategy: params.fetch(:grouping_strategy, :individual).to_sym
            )

            if result.success?
              render json: {
                work_packages: result.result[:work_packages].map { |wp| work_package_summary(wp) },
                links: result.result[:links].map { |link| link_summary(link) },
                failures: result.result[:failures],
                work_package_count: result.result[:work_package_count],
                link_count: result.result[:link_count]
              }, status: :created
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          # POST /api/v3/bim/element_links/refresh_properties
          # Refresh element properties for multiple links
          def refresh_properties
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            result = service.refresh_element_properties(
              link_ids: params[:link_ids]
            )

            if result.success?
              render json: {
                refreshed_count: result.result[:refreshed_count],
                changed_count: result.result[:changed_count],
                failed_count: result.result[:failed_count],
                changed: result.result[:changed].map { |link| link_summary(link) },
                failed: result.result[:failed]
              }
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          # POST /api/v3/bim/element_links/find_matching
          # Find elements matching filters across models
          def find_matching
            service = ::Bim::BulkLinkOperationsService.new(current_user: current_user)

            ifc_models = ::Bim::IfcModels::IfcModel.where(id: params[:ifc_model_ids])

            result = service.find_matching_elements(
              ifc_models: ifc_models,
              filters: params[:filters]
            )

            if result.success?
              render json: {
                results: result.result[:results].transform_values do |data|
                  {
                    model_id: data[:model].id,
                    model_title: data[:model].title,
                    element_ids: data[:element_ids],
                    count: data[:count]
                  }
                end,
                total_count: result.result[:total_count],
                model_count: result.result[:model_count]
              }
            else
              render json: error_response(result.message), status: :unprocessable_entity
            end
          end

          private

          def authorize_manage
            authorize(:manage_ifc_models, global: true)
          end

          def rate_limit_check
            # Simple rate limiting: max 10 bulk operations per minute per user
            cache_key = "bulk_operations:#{current_user.id}"
            count = Rails.cache.read(cache_key) || 0

            if count >= 10
              render json: error_response('Rate limit exceeded. Please try again later.'),
                     status: :too_many_requests
              return
            end

            Rails.cache.write(cache_key, count + 1, expires_in: 1.minute)
          end

          def find_work_package
            WorkPackage.find(params[:work_package_id])
          rescue ActiveRecord::RecordNotFound
            render json: error_response('Work package not found'), status: :not_found
            nil
          end

          def find_ifc_model
            ::Bim::IfcModels::IfcModel.find(params[:ifc_model_id])
          rescue ActiveRecord::RecordNotFound
            render json: error_response('IFC model not found'), status: :not_found
            nil
          end

          def find_template
            ::Bim::LinkTemplate.find(params[:template_id])
          rescue ActiveRecord::RecordNotFound
            render json: error_response('Template not found'), status: :not_found
            nil
          end

          def update_attributes_params
            params.require(:attributes).permit(
              :relationship_type,
              :status,
              element_properties: {}
            )
          end

          def work_package_template_params
            params.require(:work_package_template).permit(
              :project_id,
              :type_id,
              :subject,
              :description,
              :assigned_to_id,
              :priority_id,
              :due_date
            ).to_h
          end

          def bulk_response(data)
            {
              _type: 'BulkOperationResult',
              success_count: data[:success_count],
              failure_count: data[:failure_count],
              created: data[:created]&.map { |link| link_summary(link) },
              updated: data[:updated]&.map { |link| link_summary(link) },
              failed: data[:failed]
            }
          end

          def link_summary(link)
            {
              id: link.id,
              element_id: link.element_id,
              relationship_type: link.relationship_type,
              status: link.status,
              _links: {
                self: { href: api_v3_bim_element_link_path(link) }
              }
            }
          end

          def work_package_summary(wp)
            {
              id: wp.id,
              subject: wp.subject,
              _links: {
                self: { href: api_v3_work_package_path(wp) }
              }
            }
          end

          def error_response(message)
            {
              _type: 'Error',
              errorIdentifier: 'urn:openproject-org:api:v3:errors:InvalidRequestBody',
              message: message
            }
          end
        end
      end
    end
  end
end
