module MyPage
  class GridRegistration < ::Grids::Configuration::Registration
    grid_class 'Grids::MyPage'
    to_scope :my_page_path

    widgets 'work_packages_assigned',
            'work_packages_accountable',
            'work_packages_watched',
            'work_packages_created',
            'work_packages_calendar',
            'work_packages_table',
            'time_entries_current_user',
            'documents',
            'news'

    widget_strategy 'work_packages_table' do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, _project) { user.allowed_to_globally?(:save_queries) }
    end

    widget_strategy 'work_packages_assigned' do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, _project) { user.allowed_to_globally?(:save_queries) }
    end

    widget_strategy 'work_packages_accountable' do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, _project) { user.allowed_to_globally?(:save_queries) }
    end

    widget_strategy 'work_packages_watched' do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, _project) { user.allowed_to_globally?(:save_queries) }
    end

    widget_strategy 'work_packages_created' do
      after_destroy -> { ::Query.find_by(id: options[:queryId])&.destroy }

      allowed ->(user, _project) { user.allowed_to_globally?(:save_queries) }
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
            end_row: 7,
            start_column: 3,
            end_column: 5,
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
