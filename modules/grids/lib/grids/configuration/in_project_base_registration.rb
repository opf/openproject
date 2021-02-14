module Grids::Configuration
  class InProjectBaseRegistration < ::Grids::Configuration::Registration
    widgets 'work_packages_table',
            'work_packages_graph',
            'project_description',
            'project_status',
            'project_details',
            'subprojects',
            'work_packages_calendar',
            'work_packages_overview',
            'time_entries_project',
            'members',
            'news',
            'documents',
            'custom_text'

    remove_query_lambda = -> {
      ::Query.find_by(id: options[:queryId])&.destroy
    }

    save_or_manage_queries_lambda = ->(user, project) {
      user.allowed_to?(:save_queries, project) &&
        user.allowed_to?(:manage_public_queries, project)
    }

    queries_permission_and_ee_lambda = ->(user, project) {
      save_or_manage_queries_lambda.call(user, project) &&
        EnterpriseToken.allows_to?(:grid_widget_wp_graph)
    }

    view_work_packages_lambda = ->(user, project) {
      user.allowed_to?(:view_work_packages, project)
    }

    widget_strategy 'work_packages_table' do
      after_destroy remove_query_lambda

      allowed save_or_manage_queries_lambda

      options_representer '::API::V3::Grids::Widgets::QueryOptionsRepresenter'
    end

    widget_strategy 'work_packages_graph' do
      after_destroy remove_query_lambda

      allowed queries_permission_and_ee_lambda

      options_representer '::API::V3::Grids::Widgets::ChartOptionsRepresenter'
    end

    widget_strategy 'custom_text' do
      options_representer '::API::V3::Grids::Widgets::CustomTextOptionsRepresenter'
    end

    widget_strategy 'work_packages_overview' do
      allowed view_work_packages_lambda
    end

    widget_strategy 'work_packages_calendar' do
      allowed view_work_packages_lambda
    end

    widget_strategy 'members' do
      allowed ->(user, project) {
        user.allowed_to?(:view_members, project)
      }
    end

    widget_strategy 'news' do
      allowed ->(user, project) {
        user.allowed_to?(:view_news, project)
      }
    end

    widget_strategy 'documents' do
      allowed ->(user, project) {
        user.allowed_to?(:view_documents, project)
      }
    end

    macroed_getter_setter :view_permission
    macroed_getter_setter :edit_permission
    macroed_getter_setter :in_project_scope_path

    class << self
      def all_scopes
        view_allowed = Project.allowed_to(User.current, view_permission)

        projects = Project.where(id: view_allowed)

        projects.map { |p| url_helpers.send(to_scope, p) }
      end

      def from_scope(scope)
        # recognize_routes does not work with engine paths
        path = [OpenProject::Configuration.rails_relative_url_root,
                'projects',
                '([^/]+)',
                in_project_scope_path,
                '?'].flatten.compact.join('/')

        match = Regexp.new(path).match(scope)
        return if match.nil?

        {
          class: grid_class.constantize,
          project_id: match[1]
        }
      end

      def writable?(grid, user)
        super && user.allowed_to?(edit_permission, grid.project)
      end

      def visible(user = User.current)
        super
          .where(project_id: Project.allowed_to(user, view_permission))
      end
    end
  end
end
