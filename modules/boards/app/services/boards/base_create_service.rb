# frozen_string_literal: true

module Boards
  class BaseCreateService < ::Grids::CreateService
    protected

    def instance(attributes)
      factory_attributes = attributes.merge(scope: scope(attributes))
      super(factory_attributes)
    end

    def before_perform(params, _service_result)
      return super(params, _service_result) if grid_lacks_query?(params)

      create_query_result = create_query(params)

      return result if create_query_result.failure?

      super(params.merge(query_id: create_query_result.result.id), create_query_result)
    end

    def scope(params)
      Rails.application.routes.url_helpers.project_work_package_boards_path(params[:project])
    end

    def set_attributes_params(params)
      {}.tap do |grid_params|
        grid_params[:name] = params[:name]
        grid_params[:options] = options_for_grid(params)
        grid_params[:row_count] = 1
        grid_params[:column_count] = column_count_for_grid(params)
        grid_params[:widgets] = options_for_widgets(params)
      end
    end

    def attributes_service_class
      BaseSetAttributesService
    end

    private

    def grid_lacks_query?(_params)
      false
    end

    def create_query(params)
      Queries::CreateService.new(user: User.current)
                            .call(create_query_params(params))
    end

    def create_query_params(params)
      {
        project_id: params[:project].id,
        name: query_name(params),
        filters: query_filters(params)
      }
    end

    def query_name(_params)
      raise 'Define the query name'
    end

    def query_filters(_params)
      raise 'Define the query filters'
    end

    def options_for_grid(params)
      {}.tap do |options|
        options[:attribute] = params[:attribute]
        options[:type] = params[:attribute] == 'basic' ? 'free' : 'action'
      end
    end

    def column_count_for_grid(_params)
      4
    end

    def options_for_widgets(params)
      raise 'Define the options for the grid widgets'
    end
  end
end
