module MyPage
  class GridRegistration < ::Grids::Configuration::Registration
    grid_class 'Grids::MyPage'
    to_scope :my_page_path

    widgets 'custom_text',
            'documents',
            'work_packages_assigned',
            'work_packages_accountable',
            'work_packages_watched',
            'work_packages_created',
            'work_packages_calendar',
            'work_packages_table',
            'time_entries_current_user',
            'news'

    wp_table_strategy_proc = Proc.new do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, _project) { user.allowed_to_globally?(:save_queries) }

      options_representer '::API::V3::Grids::Widgets::QueryOptionsRepresenter'
    end

    widget_strategy 'work_packages_table', &wp_table_strategy_proc
    widget_strategy 'work_packages_assigned', &wp_table_strategy_proc
    widget_strategy 'work_packages_accountable', &wp_table_strategy_proc
    widget_strategy 'work_packages_watched', &wp_table_strategy_proc
    widget_strategy 'work_packages_created', &wp_table_strategy_proc

    widget_strategy 'time_entries_current_user' do
      options_representer '::API::V3::Grids::Widgets::TimeEntryCalendarOptionsRepresenter'
    end

    widget_strategy 'custom_text' do
      # Requiring a permission here as one is required to assign attachments.
      # Should be replaced by a global permission to have a my page
      allowed ->(user, _project) { user.allowed_to_globally?(:view_project) }

      options_representer '::API::V3::Grids::Widgets::CustomTextOptionsRepresenter'
    end

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
              name: I18n.t('js.grid.widgets.work_packages_assigned.title'),
              queryProps: {
                "columns[]": %w(id project type subject),
                filters: JSON.dump([{ "status": { "operator": "o", "values": [] } },
                                    { "assigned_to": { "operator": "=", "values": ["me"] } }])
              }
            }
          },
          {
            identifier: 'work_packages_table',
            start_row: 1,
            end_row: 2,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t('js.grid.widgets.work_packages_created.title'),
              queryProps: {
                "columns[]": %w(id project type subject),
                filters: JSON.dump([{ "status": { "operator": "o", "values": [] } },
                                    { "author": { "operator": "=", "values": ["me"] } }])
              }
            }
          }
        ]
      }
    }

    class << self
      def from_scope(scope)
        if scope == url_helpers.my_page_path
          { class: Grids::MyPage }
        end
      end

      def visible(user = User.current)
        super
          .where(user_id: user.id)
      end
    end
  end
end
