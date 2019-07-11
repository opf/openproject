class RenameMyPageWidgets < ActiveRecord::Migration[5.2]
  def up
    Grids::MyPage.includes(:widgets, user: :preference).each do |page|
      I18n.with_locale(page.user&.language.presence || 'en') do
        page.widgets.each(&method(:update_widget))
      end
    end
  end

  private

  def update_widget(widget)
    case widget.identifier
    when 'work_packages_assigned'
      update_table_widget(widget, 'assignee')
    when 'work_packages_accountable'
      update_table_widget(widget, 'responsible')
    when 'work_packages_created'
      update_table_widget(widget, 'author')
    when 'work_packages_watched'
      update_table_widget(widget, 'watcher')
    when 'work_packages_calendar', 'news', 'documents', 'time_entries_current_user'
      update_widget_name(widget)
    when 'work_packages_table'
      update_query_widget(widget)
    end
  end

  def update_table_widget(widget, filter_name)
    widget.options = {
      "name": I18n.t("js.grid.widgets.#{widget.identifier}.title"),
      "queryProps": {
        "columns[]": %w(id project type subject),
        "filters": JSON.dump([{ "status": { "operator": "o", "values": [] } },
                              { filter_name => { "operator": "=", "values": ["me"] } }])
      }
    }
    widget.identifier = 'work_packages_table'

    widget.save(validate: false)
  end

  def update_widget_name(widget)
    widget.options = {
      "name": I18n.t("js.grid.widgets.#{widget.identifier}.title")
    }

    widget.save(validate: false)
  end

  def update_query_widget(widget)
    query_id = widget.options['queryId']

    name = Query.where(id: query_id).limit(1).pluck(:name).first || I18n.t('js.grid.widgets.work_packages_table.title')

    widget.options = {
      "name": name,
      "queryId": query_id
    }

    widget.save(validate: false)
  end

  def down
    Grids::MyPage.destroy_all
  end
end
