# Update journal entries from this:
#
# {
#   "type" => "status_p_complete_changed",
#   "status_name" => status.name,
#   "status_id" => status.id,
#   "status_p_complete_change" => [20, 40]
# }
#
# to this:
#
# {
#   "type" => "status_changed",
#   "status_name" => status.name,
#   "status_id" => status.id,
#   "status_changes" => { "default_done_ratio" => [20, 40] }
# }
#
# structure needed to handle multiple changes in one cause
class FixStatusExcludedFromTotalsChangedJournalCause < ActiveRecord::Migration[7.1]
  def up
    execute(<<~SQL.squish)
      UPDATE journals
      SET cause = json_object(
        'type': 'status_changed',
        'status_id': cause -> 'status_id',
        'status_name': cause -> 'status_name',
        'status_changes': json_object(
          'default_done_ratio': cause -> 'status_p_complete_change'
        )
      )
      WHERE cause @> '{"type": "status_p_complete_changed"}';
    SQL
  end

  def down
    execute(<<~SQL.squish)
      UPDATE journals
      SET cause = json_object(
        'type': 'status_p_complete_changed',
        'status_id': cause -> 'status_id',
        'status_name': cause -> 'status_name',
        'status_p_complete_change': cause #> '{status_changes,default_done_ratio}'
      )
      WHERE cause @> '{"type": "status_changed", "status_changes":{"default_done_ratio":[]}}';
    SQL
  end
end
