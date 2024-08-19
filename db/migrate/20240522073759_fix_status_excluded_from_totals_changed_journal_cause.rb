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
    # With Postgres version 16+, it could be written as:
    # json_object(
    #   'type': 'status_changed',
    #   'status_id': cause -> 'status_id',
    #   'status_name': cause -> 'status_name',
    #   'status_changes': json_object(
    #     'default_done_ratio': cause -> 'status_p_complete_change'
    #   )
    # )
    execute(<<~SQL.squish)
      UPDATE journals
      SET cause = jsonb_set(
        jsonb_set(
          cause,
          '{type}',
          '"status_changed"'
        ),
        '{status_changes}',
        jsonb_set(
          '{"default_done_ratio": ""}'::jsonb,
          '{default_done_ratio}',
          cause -> 'status_p_complete_change'
        )
      ) - 'status_p_complete_change'
      WHERE cause @> '{"type": "status_p_complete_changed"}';
    SQL
  end

  def down
    # With Postgres version 16+, it could be written as:
    # json_object(
    #   'type': 'status_p_complete_changed',
    #   'status_id': cause -> 'status_id',
    #   'status_name': cause -> 'status_name',
    #   'status_p_complete_change': cause #> '{status_changes,default_done_ratio}'
    # )
    execute(<<~SQL.squish)
      UPDATE journals
      SET cause = jsonb_set(
        jsonb_set(
          cause,
          '{type}',
          '"status_p_complete_changed"'
        ),
        '{status_p_complete_change}',
        cause #> '{status_changes,default_done_ratio}'
      ) - 'status_changes'
      WHERE cause @> '{"type": "status_changed", "status_changes":{"default_done_ratio":[]}}';
    SQL
  end
end
