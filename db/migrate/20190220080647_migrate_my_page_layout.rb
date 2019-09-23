class MigrateMyPageLayout < ActiveRecord::Migration[5.2]
  def up
    UserPreference.transaction do

      # Remove all my page grids
      ::Grids::MyPage.destroy_all

      user_my_page_prefs.find_each do |pref|
        old_layout = pref.others.with_indifferent_access[:my_page_layout]
        next unless old_layout

        new_page = migrate_my_page(pref.user_id, old_layout)
        raise "Save failed due to #{new_page.errors.full_messages.join('. ')}" unless new_page.save

        remove_old_my_page pref
      rescue StandardError => e
        warn "Failed to migrate my_page for user##{pref.user_id}: #{e.message}"
      end
    end
  end

  def down
    # This migration is not revertible.
  end

  private

  ##
  # Migrate a single preference entry and remove the my page
  def migrate_my_page(user_id, old_layout)
    my_page = ::Grids::MyPage.new user_id: user_id, column_count: 4

    # Migrate top
    start_row = 1
    # Give every widget a fixed height of 4 rows
    widget_height = 4
    (old_layout['top'] || []).each do |block|
      map_widget my_page,
                 old_name: block,
                 start_row: start_row,
                 end_row: start_row + widget_height,
                 start_column: 1,
                 end_column: 5

      start_row += widget_height
    end

    # Migrate left
    left_row = start_row
    (old_layout['left'] || []).each do |block|
      map_widget my_page,
                 old_name: block,
                 start_row: left_row,
                 end_row: left_row + widget_height,
                 start_column: 1,
                 end_column: 3

      left_row += widget_height
    end

    # Migrate right
    right_row = start_row
    (old_layout['right'] || []).each do |block|
      map_widget my_page,
                 old_name: block,
                 start_row: right_row,
                 end_row: right_row + widget_height,
                 start_column: 3,
                 end_column: 5

      right_row += widget_height
    end

    my_page.row_count = [left_row, right_row].max - 1
    my_page
  end

  ##
  # Remove the current my page setting
  def remove_old_my_page(pref)
    # There are some cases where keys where not symbolized
    pref.others.delete(:my_page_layout)
    pref.others.delete('my_page_layout')
    pref.save
  end

  ##
  # Get all preferences with my page set that do not have
  # a grid
  def user_my_page_prefs
    pref_table = UserPreference.table_name

    ::UserPreference.where("#{pref_table}.others LIKE '%my_page_layout%'")
  end

  ##
  # Mapping of old widget names to new widgets
  def map_widget(my_page, old_name:, start_row:, end_row:, start_column:, end_column:)
    mapping = widget_mapping[old_name.to_sym]

    if mapping.nil?
      warn "Skipping unknown block #{old_name}"
      return
    end

    my_page.widgets << Grids::Widget.new(
      identifier: mapping,
      start_row: start_row,
      end_row: end_row,
      start_column: start_column,
      end_column: end_column
    )
  end

  ##
  # Widget mapping
  def widget_mapping
    @widget_mapping ||= {
      issuesassignedtome: :work_packages_assigned,
      workpackagesresponsiblefor: :work_packages_accountable,
      issuesreportedbyme: :work_packages_created,
      issueswatched: :work_packages_watched,
      news: :news,
      calendar: :work_packages_calendar,
      timelog: :time_entries_current_user,
      documents: :documents
    }
  end
end
