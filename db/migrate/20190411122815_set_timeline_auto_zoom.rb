class SetTimelineAutoZoom < ActiveRecord::Migration[5.2]
  def up
    Query.where(timeline_zoom_level: :days).update_all(timeline_zoom_level: :auto)
    change_column_default :queries, :timeline_zoom_level, 5
  end

  def down
    Query.where(timeline_zoom_level: :auto).update_all(timeline_zoom_level: :days)
    change_column_default :queries, :timeline_zoom_level, 0
  end
end
