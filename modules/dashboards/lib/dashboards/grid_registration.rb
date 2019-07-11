module Dashboards
  class GridRegistration < ::Grids::Configuration::Registration
    grid_class 'Grids::Dashboard'
    to_scope :project_dashboards_path

    widgets 'work_packages_table',
            'work_packages_graph',
            'project_description'

    widget_strategy 'work_packages_table' do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, project) {
        user.allowed_to?(:save_queries, project) &&
          user.allowed_to?(:manage_public_queries, project)
      }
    end

    widget_strategy 'work_packages_graph' do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, project) {
        user.allowed_to?(:save_queries, project) &&
          user.allowed_to?(:manage_public_queries, project)
      }
    end

    defaults -> {
      {
        row_count: 7,
        column_count: 4,
        widgets: [
          {
            identifier: 'work_packages_table',
            start_row: 1,
            end_row: 7,
            start_column: 1,
            end_column: 3,
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

    class << self
      def all_scopes
        view_allowed = Project.allowed_to(User.current, :view_dashboards)

        projects = Project
                   .where(id: view_allowed)

        projects.map { |p| url_helpers.project_dashboards_path(p) }
      end

      def from_scope(scope)
        # recognize_routes does not work with engine paths
        path = [OpenProject::Configuration.rails_relative_url_root, 'projects', '([^/]+)', 'dashboards', '?'].compact.join('/')
        match = Regexp.new(path).match(scope)
        return if match.nil?

        {
          class: ::Grids::Dashboard,
          project_id: match[1]
        }
      end

      def writable?(grid, user)
        super && user.allowed_to?(:manage_dashboards, grid.project)
      end

      def visible(user = User.current)
        super
          .where(project_id: Project.allowed_to(user, :view_dashboards))
      end
    end
  end
end
