# frozen_string_literal: true

module API
  module V3
    module Bim
      class ElementsController < ApplicationController
        before_action :find_ifc_model
        before_action :authorize_view_access
        before_action :authorize_edit_access, only: [:update_properties]

        # GET /api/v3/bim/ifc_models/:ifc_model_id/elements/:guid/properties
        # Get element properties grouped by category
        def properties
          element_guid = params[:guid]

          service = ::Bim::Services::ElementPropertiesService.new(@ifc_model, element_guid)
          props = service.properties

          if props.empty?
            return render json: { error: 'Element not found' }, status: :not_found
          end

          render json: {
            _type: 'BimElementProperties',
            model_id: @ifc_model.id,
            element_guid: element_guid,
            properties: {
              basic: props[:basic] || {},
              geometry: props[:geometry] || {},
              materials: props[:materials] || {},
              status: props[:status] || {},
              custom: props[:custom] || {}
            },
            _links: {
              self: { href: api_v3_bim_element_properties_path(@ifc_model.id, element_guid) },
              related: { href: api_v3_bim_element_related_path(@ifc_model.id, element_guid) },
              history: { href: api_v3_bim_element_history_path(@ifc_model.id, element_guid) },
              model: { href: api_v3_bim_ifc_model_path(@ifc_model.id) }
            }
          }
        end

        # PATCH /api/v3/bim/ifc_models/:ifc_model_id/elements/:guid/properties
        # Update element properties (custom properties only)
        def update_properties
          element_guid = params[:guid]
          properties = params[:properties] || {}

          service = ::Bim::Services::ElementPropertiesService.new(@ifc_model, element_guid)
          result = service.update_properties(properties.to_unsafe_h.symbolize_keys, user: current_user)

          if result[:success]
            render json: {
              _type: 'BimElementPropertiesUpdate',
              success: true,
              element_guid: element_guid,
              updated_properties: result[:properties],
              _links: {
                self: { href: api_v3_bim_element_properties_path(@ifc_model.id, element_guid) }
              }
            }
          else
            render json: { error: result[:error] }, status: :unprocessable_entity
          end
        end

        # GET /api/v3/bim/ifc_models/:ifc_model_id/elements/:guid/related
        # Get related elements (parent, children)
        def related
          element_guid = params[:guid]

          service = ::Bim::Services::ElementPropertiesService.new(@ifc_model, element_guid)
          related_elements = service.related_elements

          render json: {
            _type: 'BimElementRelated',
            element_guid: element_guid,
            related_elements: related_elements.map { |rel| related_element_representer(rel) },
            count: related_elements.size,
            _links: {
              self: { href: api_v3_bim_element_related_path(@ifc_model.id, element_guid) },
              element: { href: api_v3_bim_element_properties_path(@ifc_model.id, element_guid) }
            }
          }
        end

        # GET /api/v3/bim/ifc_models/:ifc_model_id/elements/:guid/history
        # Get property change history from audit logs
        def history
          element_guid = params[:guid]

          service = ::Bim::Services::ElementPropertiesService.new(@ifc_model, element_guid)
          history = service.property_history

          render json: {
            _type: 'BimElementHistory',
            element_guid: element_guid,
            history: history.map { |entry| history_entry_representer(entry) },
            total_entries: history.size,
            _links: {
              self: { href: api_v3_bim_element_history_path(@ifc_model.id, element_guid) },
              element: { href: api_v3_bim_element_properties_path(@ifc_model.id, element_guid) }
            }
          }
        end

        private

        def find_ifc_model
          @ifc_model = ::Bim::IfcModel::IfcModel.find(params[:ifc_model_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC Model not found' }, status: :not_found
        end

        def authorize_view_access
          unless current_user.allowed_in_project?(:view_ifc_models, @ifc_model.project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def authorize_edit_access
          unless current_user.allowed_in_project?(:manage_ifc_models, @ifc_model.project)
            render json: { error: 'Edit permission required' }, status: :forbidden
          end
        end

        def related_element_representer(rel)
          {
            relationship: rel[:relationship],
            guid: rel[:guid],
            name: rel[:name],
            type: rel[:type],
            _links: {
              properties: { href: api_v3_bim_element_properties_path(@ifc_model.id, rel[:guid]) }
            }
          }
        end

        def history_entry_representer(entry)
          {
            timestamp: entry[:timestamp],
            user: entry[:user],
            action: entry[:action],
            changes: entry[:changes],
            details: entry[:details]
          }
        end
      end
    end
  end
end
