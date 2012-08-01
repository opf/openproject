require_dependency 'query'

module Backlogs::Patches::QueryPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods

      add_available_column(QueryColumn.new(:story_points, :sortable => "#{Issue.table_name}.story_points"))
      add_available_column(QueryColumn.new(:remaining_hours, :sortable => "#{Issue.table_name}.remaining_hours"))

      add_available_column(QueryColumn.new(:position,
                                           :default_order => 'asc',
                                           # Sort by position only, always show issues without a position at the end
                                           :sortable => "CASE WHEN #{Issue.table_name}.position IS NULL THEN 1 ELSE 0 END ASC, #{Issue.table_name}.position"
                                          ))

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

Query.send(:include, Backlogs::Patches::QueryPatch)
