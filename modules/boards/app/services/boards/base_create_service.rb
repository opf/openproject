# frozen_string_literal: true

module Boards
  class BaseCreateService < ::Grids::CreateService
    protected

    def instance(attributes)
      Boards::Grid.new(
        name: attributes[:name],
        project: attributes[:project],
        row_count: row_count_for_board,
        column_count: column_count_for_board
      )
    end

    def before_perform(params, _service_result)
      return super if no_widgets_initially?

      create_query_result = create_query(params)

      return create_query_result if create_query_result.failure?

      super(params.merge(query_id: create_query_result.result.id), create_query_result)
    end

    def set_attributes_params(params)
      {}.tap do |grid_params|
        grid_params[:options] = options_for_grid(params)
        grid_params[:widgets] = options_for_widgets(params)
      end
    end

    def attributes_service_class
      BaseSetAttributesService
    end

    private

    def no_widgets_initially?
      false
    end

    def create_query(params)
      Queries::CreateService.new(user: User.current)
                            .call(create_query_params(params))
    end

    def create_query_params(params)
      default_create_query_params(params).merge(
        name: query_name,
        filters: query_filters
      )
    end

    def default_create_query_params(params)
      {
        project: params[:project],
        public: true,
        sort_criteria: query_sort_criteria
      }
    end

    def query_name
      raise "Define the query name"
    end

    def query_filters
      raise "Define the query filters"
    end

    def query_sort_criteria
      [[:manual_sorting, "asc"], [:id, "asc"]]
    end

    def options_for_grid(params)
      {}.tap do |options|
        if params[:attribute] == "basic"
          options[:type] = "free"
        else
          options[:type] = "action"
          options[:attribute] = params[:attribute]
        end
      end
    end

    def options_for_widgets(_params)
      return [] if no_widgets_initially?

      raise "Define the options for the grid widgets"
    end

    def row_count_for_board
      1
    end

    def column_count_for_board
      4
    end
  end
end
