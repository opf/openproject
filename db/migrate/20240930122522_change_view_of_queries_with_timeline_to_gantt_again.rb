require_relative "20231201085450_change_view_of_queries_with_timeline_to_gantt"

# Inherit from the original migration `ChangeViewOfQueriesWithTimelineToGantt`
# to avoid duplicating it.
#
# The original migration was fine, but it was applied too early: in OpenProject
# 13.2.0 the migration would already have been run and it was still possible to
# create Gantt queries inside the work packages module. Such queries were not
# migrated.
#
# This was registered as bug #56769.
#
# This migration runs the original migration again to ensure all queries
# displayed as Gantt charts are displayed in the right module.
class ChangeViewOfQueriesWithTimelineToGanttAgain < ChangeViewOfQueriesWithTimelineToGantt
end
