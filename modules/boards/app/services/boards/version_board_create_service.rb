# frozen_string_literal: true

module Boards
  class VersionBoardCreateService < BaseCreateService
    protected

    def before_perform(params, _service_result)
      create_queries_results = create_queries(params)

      return create_queries_results.find(&:failure?) if create_queries_results.any?(&:failure?)

      set_attributes(params.merge(query_ids: create_queries_results.map(&:result).map(&:id)))
    end

    private

    def create_queries(params)
      versions(params).map do |version|
        Queries::CreateService.new(user: User.current)
                              .call(create_query_params(params, version))
      end
    end

    def versions(params)
      @versions ||= params[:project].shared_versions.with_status_open
    end

    def create_query_params(params, version)
      {
        project: params[:project],
        name: query_name(version),
        public: true,
        filters: query_filters(version)
      }
    end

    def query_name(version)
      version.name
    end

    def query_filters(version)
      [{ version_id: { operator: '=', values: [version.id] } }]
    end

    def options_for_widgets(params)
      query_ids_with_versions = params[:query_ids].zip(versions(params))
      query_ids_with_versions.map.with_index do |(query_id, version), index|
        Grids::Widget.new(
          start_row: 1,
          start_column: 1 + index,
          end_row: 2,
          end_column: 2 + index,
          identifier: "work_package_query",
          options: {
            "queryId" => query_id,
            "filters" => query_filters(version)
          }
        )
      end
    end
  end
end
