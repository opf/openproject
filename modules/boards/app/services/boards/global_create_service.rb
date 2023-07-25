# frozen_string_literal: true

module Boards
  class GlobalCreateService < ::Grids::CreateService
    def initialize(user:, contract_class: ::Boards::GlobalCreateContract, contract_options: nil)
      super
    end

    protected

    def instance(attributes)
      factory_attributes = set_attributes_params(attributes).merge(scope: scope(attributes))
      super(factory_attributes)
    end

    def before_perform(params, _service_result)
      create_query_result = create_query(params)

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
      GlobalSetAttributesService
    end

    private

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

    def query_name(params)
      {
        'basic' => 'Unnamed list',
        'status' => default_status.name
      }.fetch(params[:attribute])
    end

    def query_filters(params)
      {
        'basic' => [{ manual_sort: { operator: 'ow', values: [] } }],
        'status' => [{ status_id: { operator: '=', values: [default_status.id] } }]
      }.fetch(params[:attribute])
    end

    def default_status
      @default_status ||= ::Status.default
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
      {
        'basic' => [
          Grids::Widget.new(
            start_row: 1,
            start_column: 1,
            end_row: 2,
            end_column: 2,
            identifier: "work_package_query",
            options: {
              "queryId" => params[:query_id],
              "filters" => query_filters(params)
            }
          )
        ],
        'status' => [
          Grids::Widget.new(
            start_row: 1,
            start_column: 1,
            end_row: 2,
            end_column: 2,
            identifier: "work_package_query",
            options: {
              "queryId" => params[:query_id],
              "filters" => query_filters(params)
            }
          )
        ]
      }.fetch(params[:attribute])
    end
  end
end
