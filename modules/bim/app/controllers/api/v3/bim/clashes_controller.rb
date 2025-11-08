# frozen_string_literal: true

module API
  module V3
    module Bim
      class ClashesController < ::API::V3::BaseController
        before_action :find_clash, only: %i[show update destroy approve resolve]
        before_action :authorize_view, only: %i[index show statistics]
        before_action :authorize_manage, only: %i[create update destroy detect approve resolve]

        # GET /api/v3/bim/clashes
        def index
          query = build_query_from_params
          clashes = query.results
          total = query.results.count

          render json: {
            _type: 'Collection',
            total: total,
            count: clashes.size,
            _embedded: {
              elements: clashes.map { |clash| clash_representer(clash) }
            }
          }
        end

        # GET /api/v3/bim/clashes/:id
        def show
          render json: clash_representer(@clash, detailed: true)
        end

        # POST /api/v3/bim/clashes
        def create
          clash = ::Bim::Clash.new(create_params)

          if clash.save
            render json: clash_representer(clash), status: :created
          else
            render json: error_response(clash.errors), status: :unprocessable_entity
          end
        end

        # PATCH /api/v3/bim/clashes/:id
        def update
          if @clash.update(update_params)
            render json: clash_representer(@clash)
          else
            render json: error_response(@clash.errors), status: :unprocessable_entity
          end
        end

        # DELETE /api/v3/bim/clashes/:id
        def destroy
          if @clash.destroy
            head :no_content
          else
            render json: error_response(@clash.errors), status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/clashes/detect
        def detect
          ifc_model = find_ifc_model
          return unless ifc_model

          service = ::Bim::ClashDetectionService.new(
            ifc_model: ifc_model,
            options: detection_options
          )

          result = service.detect_all_clashes

          if result.success?
            render json: {
              _type: 'ClashDetectionResult',
              clashes: result.result[:clashes].map { |c| clash_representer(c) },
              count: result.result[:count],
              detection_run_id: result.result[:detection_run_id],
              detected_at: result.result[:detected_at]
            }, status: :created
          else
            render json: error_response(result.message), status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/clashes/:id/approve
        def approve
          user = current_user
          comment = params[:comment]

          if @clash.approve!(user: user, comment: comment)
            render json: clash_representer(@clash)
          else
            render json: error_response(@clash.errors), status: :unprocessable_entity
          end
        end

        # POST /api/v3/bim/clashes/:id/resolve
        def resolve
          user = current_user
          resolution_type = params[:resolution_type]
          comment = params[:comment]

          if @clash.resolve!(user: user, resolution_type: resolution_type, comment: comment)
            render json: clash_representer(@clash)
          else
            render json: error_response(@clash.errors), status: :unprocessable_entity
          end
        end

        # GET /api/v3/bim/clashes/statistics
        def statistics
          ifc_model = find_ifc_model
          return unless ifc_model

          service = ::Bim::ClashDetectionService.new(ifc_model: ifc_model)
          stats = service.clash_statistics

          render json: {
            _type: 'ClashStatistics',
            total: stats[:total],
            by_type: stats[:by_type],
            by_severity: stats[:by_severity],
            by_status: stats[:by_status],
            unresolved: stats[:unresolved],
            critical: stats[:critical],
            recent_24h: stats[:recent_24h]
          }
        end

        private

        def find_clash
          @clash = ::Bim::Clash.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: error_response('Clash not found'), status: :not_found
        end

        def find_ifc_model
          model = ::Bim::IfcModels::IfcModel.find(params[:ifc_model_id])
          model
        rescue ActiveRecord::RecordNotFound
          render json: error_response('IFC model not found'), status: :not_found
          nil
        end

        def authorize_view
          authorize_any(%i[view_ifc_models view_work_packages], global: true)
        end

        def authorize_manage
          authorize(:manage_ifc_models, global: true)
        end

        def create_params
          params.require(:clash).permit(
            :ifc_model_id,
            :element_a_id,
            :element_b_id,
            :clash_type,
            :severity,
            :distance,
            :overlap_volume,
            clash_point: {},
            geometry_data: {}
          )
        end

        def update_params
          params.require(:clash).permit(
            :status,
            :severity,
            :assigned_to_id,
            :work_package_id,
            :description
          )
        end

        def detection_options
          opts = {}
          opts[:clearance_distance] = params[:clearance_distance].to_f if params[:clearance_distance]
          opts[:soft_clash_distance] = params[:soft_clash_distance].to_f if params[:soft_clash_distance]
          opts[:detect_hard_clashes] = params[:detect_hard_clashes] if params[:detect_hard_clashes]
          opts[:detect_soft_clashes] = params[:detect_soft_clashes] if params[:detect_soft_clashes]
          opts[:element_type_filters] = params[:element_types] if params[:element_types]
          opts
        end

        def build_query_from_params
          query = ::Bim::Clash.all

          query = query.where(ifc_model_id: params[:ifc_model_id]) if params[:ifc_model_id]
          query = query.where(clash_type: params[:clash_type]) if params[:clash_type]
          query = query.where(severity: params[:severity]) if params[:severity]
          query = query.where(status: params[:status]) if params[:status]
          query = query.where(work_package_id: params[:work_package_id]) if params[:work_package_id]
          query = query.for_element(params[:element_id]) if params[:element_id]

          page = params[:page].to_i.positive? ? params[:page].to_i : 1
          per_page = [params[:per_page].to_i, 100].min
          per_page = 20 if per_page.zero?

          PaginatedQuery.new(query, page: page, per_page: per_page)
        end

        def clash_representer(clash, detailed: false)
          base = {
            _type: 'Clash',
            id: clash.id,
            element_a_id: clash.element_a_id,
            element_b_id: clash.element_b_id,
            clash_type: clash.clash_type,
            severity: clash.severity,
            status: clash.status,
            distance: clash.distance,
            detected_at: clash.detected_at.iso8601,
            _links: {
              self: { href: api_v3_bim_clash_path(clash) },
              ifc_model: { href: api_v3_bim_ifc_model_path(clash.ifc_model_id) }
            }
          }

          if detailed
            base.merge!(
              overlap_volume: clash.overlap_volume,
              clash_point: clash.clash_point,
              detection_run_id: clash.detection_run_id,
              description: clash.description,
              created_at: clash.created_at.iso8601,
              updated_at: clash.updated_at.iso8601
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
        end
      end
    end
  end
end
