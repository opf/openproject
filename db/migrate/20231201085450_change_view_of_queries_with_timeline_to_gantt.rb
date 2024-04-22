class ChangeViewOfQueriesWithTimelineToGantt < ActiveRecord::Migration[7.0]
  class MigrationQuery < ApplicationRecord
    self.table_name = "queries"
  end

  class MigrationView < ApplicationRecord
    self.table_name = "views"

    # disable STI
    self.inheritance_column = :_type_disabled

    belongs_to :query, class_name: "MigrationQuery"
  end

  def up
    update_view_type_for_timeline_queries(from_view_type: "work_packages_table", to_view_type: "gantt")
  end

  def down
    update_view_type_for_timeline_queries(from_view_type: "gantt", to_view_type: "work_packages_table")
  end

  private

  def update_view_type_for_timeline_queries(from_view_type:, to_view_type:)
    MigrationView
      .joins(:query)
      .where("queries.timeline_visible": true)
      .where(type: from_view_type)
      .update_all(type: to_view_type)
  end
end
