# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module Bim
      class IfcModelsController < ::API::V3::BaseController
        before_action :find_ifc_model, only: %i[show conversion_logs metadata refresh_metadata]
        before_action :authorize_view, only: %i[index show conversion_logs metadata]
        before_action :authorize_manage, only: %i[create update destroy refresh_metadata]

        # GET /api/v3/bim/ifc_models
        def index
          project = find_project
          ifc_models = project.ifc_models.includes(:ifc_model_metadata)

          render json: {
            _type: 'Collection',
            total: ifc_models.size,
            count: ifc_models.size,
            _embedded: {
              elements: ifc_models.map { |model| ifc_model_representer(model) }
            }
          }
        end

        # GET /api/v3/bim/ifc_models/:id
        def show
          render json: ifc_model_representer(@ifc_model, detailed: true)
        end

        # GET /api/v3/bim/ifc_models/:id/conversion_logs
        # Returns detailed conversion logs for the model
        def conversion_logs
          render json: {
            _type: 'IfcModelConversionLogs',
            ifc_model_id: @ifc_model.id,
            conversion_status: @ifc_model.conversion_status,
            conversion_stage: @ifc_model.conversion_stage,
            conversion_progress: @ifc_model.conversion_progress,
            conversion_started_at: @ifc_model.conversion_started_at,
            conversion_completed_at: @ifc_model.conversion_completed_at,
            conversion_error_message: @ifc_model.conversion_error_message,
            logs: @ifc_model.conversion_logs || []
          }
        end

        # GET /api/v3/bim/ifc_models/:id/metadata
        # Returns detailed metadata for the model
        def metadata
          metadata = @ifc_model.ifc_model_metadata

          if metadata
            render json: {
              _type: 'IfcModelMetadata',
              ifc_model_id: @ifc_model.id,
              ifc_version: metadata.ifc_version,
              file_schema: metadata.file_schema,
              file_checksum: metadata.file_checksum,
              entity_count: metadata.entity_count,
              geometry_count: metadata.geometry_count,
              spatial_structure: metadata.spatial_structure,
              property_sets: metadata.property_sets,
              quantities: metadata.quantities,
              classifications: metadata.classifications,
              materials: metadata.materials,
              types: metadata.types,
              validation_result: metadata.validation_result,
              estimated_conversion_time: metadata.estimated_conversion_time,
              actual_conversion_time: metadata.actual_conversion_time,
              summary: metadata.summary,
              created_at: metadata.created_at,
              updated_at: metadata.updated_at
            }
          else
            render json: {
              _type: 'IfcModelMetadata',
              ifc_model_id: @ifc_model.id,
              message: 'Metadata not yet extracted'
            }, status: :not_found
          end
        end

        # POST /api/v3/bim/ifc_models/:id/refresh_metadata
        # Triggers metadata extraction for the model
        def refresh_metadata
          service = ::Bim::IfcModels::MetadataExtractorService.new(@ifc_model)
          result = service.call

          if result.success?
            render json: {
              _type: 'IfcModelMetadata',
              message: 'Metadata extraction triggered successfully',
              ifc_model_id: @ifc_model.id
            }, status: :accepted
          else
            render json: error_response(result.errors), status: :unprocessable_entity
          end
        end

        private

        def find_ifc_model
          @ifc_model = ::Bim::IfcModels::IfcModel.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { message: 'IFC model not found' }, status: :not_found
        end

        def find_project
          project_id = params[:project_id] || params.dig(:filters, :project_id)
          Project.find(project_id)
        rescue ActiveRecord::RecordNotFound
          render json: { message: 'Project not found' }, status: :not_found
        end

        def ifc_model_representer(ifc_model, detailed: false)
          base = {
            _type: 'IfcModel',
            id: ifc_model.id,
            title: ifc_model.title,
            is_default: ifc_model.is_default,
            conversion_status: ifc_model.conversion_status,
            conversion_stage: ifc_model.conversion_stage,
            conversion_progress: ifc_model.conversion_progress,
            created_at: ifc_model.created_at,
            updated_at: ifc_model.updated_at,
            _links: {
              self: { href: api_v3_bim_ifc_model_path(ifc_model.id) },
              conversionLogs: { href: conversion_logs_api_v3_bim_ifc_model_path(ifc_model.id) },
              metadata: { href: metadata_api_v3_bim_ifc_model_path(ifc_model.id) },
              project: { href: api_v3_project_path(ifc_model.project_id) }
            }
          }

          if detailed && ifc_model.ifc_model_metadata
            metadata = ifc_model.ifc_model_metadata
            base[:metadata_summary] = {
              ifc_version: metadata.ifc_version,
              entity_count: metadata.entity_count,
              geometry_count: metadata.geometry_count,
              complexity_score: metadata.complexity_score,
              validation_passed: metadata.validation_passed?,
              has_duplicates: metadata.duplicate?
            }
          end

          base
        end

        def error_response(errors)
          {
            _type: 'Error',
            errorIdentifier: 'urn:openproject-org:api:v3:errors:PropertyConstraintViolation',
            message: errors.is_a?(String) ? errors : errors.full_messages.join(', ')
          }
        end

        def authorize_view
          authorize_global(:view_ifc_models)
        end

        def authorize_manage
          authorize_global(:manage_ifc_models)
        end
      end
    end
  end
end
