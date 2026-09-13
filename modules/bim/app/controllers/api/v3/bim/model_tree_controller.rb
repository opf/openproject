# frozen_string_literal: true

module API
  module V3
    module Bim
      class ModelTreeController < ApplicationController
        before_action :find_ifc_model
        before_action :authorize_view_access

        # GET /api/v3/bim/ifc_models/:id/tree
        # Get root nodes of model tree
        def index
          view_mode = params[:view_mode] || 'spatial'

          service = ::Bim::Services::ModelTreeService.new(@ifc_model, view_mode: view_mode)
          root_nodes = service.root_nodes

          render json: {
            _type: 'BimModelTree',
            model_id: @ifc_model.id,
            view_mode: view_mode,
            available_modes: ::Bim::Services::ModelTreeService::VIEW_MODES,
            root_nodes: root_nodes.map { |node| tree_node_representer(node) },
            total_nodes: root_nodes.size,
            _links: {
              self: { href: api_v3_bim_ifc_model_tree_index_path(@ifc_model.id, view_mode: view_mode) },
              model: { href: api_v3_bim_ifc_model_path(@ifc_model.id) }
            }
          }
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        end

        # GET /api/v3/bim/ifc_models/:id/tree/nodes/:node_id/children
        # Get children of a specific node (lazy loading)
        def children
          node_id = params[:node_id]
          view_mode = params[:view_mode] || 'spatial'

          service = ::Bim::Services::ModelTreeService.new(@ifc_model, view_mode: view_mode)
          child_nodes = service.children_of(node_id)

          render json: {
            _type: 'BimModelTreeChildren',
            model_id: @ifc_model.id,
            parent_node_id: node_id,
            view_mode: view_mode,
            children: child_nodes.map { |node| tree_node_representer(node) },
            children_count: child_nodes.size,
            _links: {
              self: { href: api_v3_bim_ifc_model_tree_children_path(@ifc_model.id, node_id, view_mode: view_mode) },
              parent: { href: api_v3_bim_ifc_model_tree_index_path(@ifc_model.id, view_mode: view_mode) }
            }
          }
        end

        # POST /api/v3/bim/ifc_models/:id/tree/search
        # Search tree nodes
        def search
          query = params[:query]
          filters = parse_filters(params[:filters] || {})
          view_mode = params[:view_mode] || 'spatial'

          if query.blank? && filters.empty?
            return render json: { error: 'Query or filters required' }, status: :bad_request
          end

          service = ::Bim::Services::ModelTreeService.new(@ifc_model, view_mode: view_mode)
          results = service.search(query, filters)

          render json: {
            _type: 'BimModelTreeSearchResults',
            model_id: @ifc_model.id,
            query: query,
            filters: filters,
            results: results.map { |result| search_result_representer(result) },
            total_results: results.size,
            _links: {
              self: { href: api_v3_bim_ifc_model_tree_search_path(@ifc_model.id) },
              tree: { href: api_v3_bim_ifc_model_tree_index_path(@ifc_model.id, view_mode: view_mode) }
            }
          }
        end

        private

        def find_ifc_model
          @ifc_model = ::Bim::IfcModel::IfcModel.find(params[:id] || params[:ifc_model_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'IFC Model not found' }, status: :not_found
        end

        def authorize_view_access
          unless current_user.allowed_in_project?(:view_ifc_models, @ifc_model.project)
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end

        def parse_filters(filters_param)
          filters = {}
          filters[:types] = filters_param[:types] if filters_param[:types].present?
          filters[:levels] = filters_param[:levels] if filters_param[:levels].present?
          filters[:disciplines] = filters_param[:disciplines] if filters_param[:disciplines].present?
          filters
        end

        def tree_node_representer(node)
          {
            id: node[:id],
            name: node[:name],
            type: node[:type],
            guid: node[:guid],
            level: node[:level],
            children_count: node[:children_count],
            has_children: node[:has_children],
            visible: node[:visible],
            selected: node[:selected],
            icon: node[:icon],
            metadata: node[:metadata],
            _links: {
              children: node[:has_children] ? {
                href: api_v3_bim_ifc_model_tree_children_path(@ifc_model.id, node[:id])
              } : nil
            }.compact
          }
        end

        def search_result_representer(result)
          {
            id: result[:id],
            name: result[:name],
            type: result[:type],
            guid: result[:guid],
            level: result[:level],
            match_type: result[:match_type],
            _links: {
              element: result[:guid] ? {
                href: api_v3_bim_element_path(@ifc_model.id, result[:guid])
              } : nil
            }.compact
          }
        end
      end
    end
  end
end
