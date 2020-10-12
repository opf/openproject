module Dashboards
  class GridRegistration < ::Grids::Configuration::InProjectBaseRegistration
    grid_class 'Grids::Dashboard'
    to_scope :project_dashboards_path

    defaults -> {
      {
        row_count: 1,
        column_count: 2,
        widgets: [
          {
            identifier: 'work_packages_table',
            start_row: 1,
            end_row: 2,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t('js.grid.widgets.work_packages_table.title'),
              queryProps: {
                "columns[]": %w(id project type subject),
                filters: JSON.dump([{ "status": { "operator": "o", "values": [] } }])
              }
            }
          }
        ]
      }
    }

    view_permission :view_dashboards
    edit_permission :manage_dashboards
    in_project_scope_path ['dashboards']
  end
end
