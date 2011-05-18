require_dependency 'query'

module Backlogs
  module QueryPatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        # Same as typing in the class
        base.class_eval do
            unloadable # Send unloadable so it will not be unloaded in development
            base.add_available_column(QueryColumn.new(:story_points, :sortable => "#{Issue.table_name}.story_points"))
            base.add_available_column(QueryColumn.new(:remaining_hours, :sortable => "#{Issue.table_name}.remaining_hours"))
            base.add_available_column(QueryColumn.new(:velocity_based_estimate))

            base.add_available_column(QueryColumn.new(:position,
                                      :sortable => [
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
                                      ],
                                      :default_order => 'asc'))


            alias_method_chain :available_filters, :backlogs_issue_type
            alias_method_chain :sql_for_field, :backlogs_issue_type
        end

    end

    module InstanceMethods
        def available_filters_with_backlogs_issue_type
            @available_filters = available_filters_without_backlogs_issue_type

            if Story.trackers.length == 0 or Task.tracker.blank?
                backlogs_filters = { }
            else
                backlogs_filters = {
                        "backlogs_issue_type" => {  :type => :list,
                                                    :values => [[l(:story, :scope => [:backlogs]), "story"], [l(:task, :scope => [:backlogs]), "task"], [l(:impediment, :scope => [:backlogs]), "impediment"], [l(:any, :scope => [:backlogs]), "any"]],
                                                    :order => 20 }
                    }
            end

            return @available_filters.merge(backlogs_filters)
        end

        def sql_for_field_with_backlogs_issue_type(field, operator, v, db_table, db_field, is_custom_filter=false)
            if field == "backlogs_issue_type"
                db_table = Issue.table_name

                sql = []

                selected_values = values_for(field)
                selected_values = ['story', 'task'] if selected_values.include?('any')

                story_trackers = Story.trackers.collect{|val| "#{val}"}.join(",")
                all_trackers = (Story.trackers + [Task.tracker]).collect{|val| "#{val}"}.join(",")

                selected_values.each { |val|
                    case val
                        when "story"
                            sql << "(#{db_table}.tracker_id in (#{story_trackers}))"
                        when "task"
                            sql << "(#{db_table}.tracker_id = #{Task.tracker} and not #{db_table}.parent_id is NULL)"
                        when "impediment"
                            sql << "(#{db_table}.id in (
                                  select issue_from_id
                                  from issue_relations ir
                                  join issues blocked
                                  on
                                    blocked.id = ir.issue_to_id
                                    and blocked.tracker_id in (#{all_trackers})
                                  where ir.relation_type = 'blocks'
                                ) and #{db_table}.parent_id is NULL)"
                    end
                }

                case operator
                    when "="
                        sql = sql.join(" or ")
                    when "!"
                        sql = "not (" + sql.join(" or ") + ")"
                end

                return sql

            else
                return sql_for_field_without_backlogs_issue_type(field, operator, v, db_table, db_field, is_custom_filter)
            end

        end
    end

    module ClassMethods
        # Setter for +available_columns+ that isn't provided by the core.
        def available_columns=(v)
            self.available_columns = (v)
        end

        # Method to add a column to the +available_columns+ that isn't provided by the core.
        def add_available_column(column)
            self.available_columns << (column)
        end
    end
  end
end

Query.send(:include, Backlogs::QueryPatch) unless Query.included_modules.include? Backlogs::QueryPatch
