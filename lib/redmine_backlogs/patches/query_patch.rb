require_dependency 'query'

module RedmineBacklogs::Patches::QueryPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods

      add_available_column(QueryColumn.new(:story_points, :sortable => "#{Issue.table_name}.story_points"))
      add_available_column(QueryColumn.new(:remaining_hours, :sortable => "#{Issue.table_name}.remaining_hours"))

      add_available_column(QueryColumn.new(:position, :default_order => 'asc', :sortable => [
        # sprint startdate
        "coalesce((select start_date from versions where versions.id = issues.fixed_version_id), '1900-01-01')",

        # sprint name, in case start dates are the same
        "(select name from versions where versions.id = issues.fixed_version_id)",

        # make sure stories with NULL
        # position sort-last
        "(select case when root.position is null then 1 else 0 end from issues root where issues.root_id = root.id)",

        # story position
        "(select root.position from issues root where issues.root_id = root.id)",

        # story ID, in case positions
        # are the same (SHOULD NOT HAPPEN!).
        # DO NOT CHANGE; root_id is the only field that sorts the same for stories _and_
        # the tasks it has.
        "issues.root_id",

        # order in task tree
        "issues.lft"
      ]))

      alias_method_chain :available_filters, :backlogs_issue_type
      alias_method_chain :sql_for_field, :backlogs_issue_type
    end
  end

  module InstanceMethods
    def available_filters_with_backlogs_issue_type
      available_filters_without_backlogs_issue_type.tap do |filters|
        if backlogs_configured? and backlogs_enabled?
          filters["backlogs_issue_type"] = {
            :type => :list,
            :values => [[l(:story, :scope => [:backlogs]), "story"],
                        [l(:task, :scope => [:backlogs]), "task"],
                        [l(:impediment, :scope => [:backlogs]), "impediment"],
                        [l(:any, :scope => [:backlogs]), "any"]],
            :order => 20
          }
        end
      end
    end

    def sql_for_field_with_backlogs_issue_type(field, operator, v, db_table, db_field, is_custom_filter=false)
      if field == "backlogs_issue_type"
        db_table = Issue.table_name

        sql = []

        selected_values = values_for(field)
        selected_values = ['story', 'task'] if selected_values.include?('any')

        story_trackers = Story.trackers.collect { |val| "#{val}" }.join(",")
        all_trackers = (Story.trackers + [Task.tracker]).collect { |val| "#{val}" }.join(",")

        selected_values.each do |val|
          case val
          when "story"
            sql << "(#{db_table}.tracker_id IN (#{story_trackers}))"
          when "task"
            sql << "(#{db_table}.tracker_id = #{Task.tracker} AND NOT #{db_table}.parent_id IS NULL)"
          when "impediment"
            sql << "(#{db_table}.id IN (
                  select issue_from_id
                  FROM issue_relations ir
                  JOIN issues blocked
                  ON
                    blocked.id = ir.issue_to_id
                    AND blocked.tracker_id IN (#{all_trackers})
                  WHERE ir.relation_type = 'blocks'
                ) AND #{db_table}.parent_id IS NULL)"
          end
        end

        case operator
        when "="
          sql = sql.join(" OR ")
        when "!"
          sql = "NOT (" + sql.join(" OR ") + ")"
        end

        sql
      else
        sql_for_field_without_backlogs_issue_type(field, operator, v, db_table, db_field, is_custom_filter)
      end
    end

    protected

    def backlogs_configured?
      Story.trackers.present? and Task.tracker.present?
    end

    def backlogs_enabled?
      project.blank? or project.module_enabled?(:backlogs)
    end
  end
end

Query.send(:include, RedmineBacklogs::Patches::QueryPatch)
