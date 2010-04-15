require_dependency 'query'

module QueryPatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        # Same as typing in the class 
        base.class_eval do
            unloadable # Send unloadable so it will not be unloaded in development
            base.add_available_column(QueryColumn.new(:story_points, :sortable => "#{Issue.table_name}.story_points"))
            base.add_available_column(QueryColumn.new(:remaining_hours, :sortable => "#{Issue.table_name}.remaining_hours"))

            alias_method_chain :available_filters, :backlogs_issue_type
            alias_method_chain :sql_for_field, :backlogs_issue_type
            alias_method_chain :columns, :backlogs_story_columns
        end

    end

    module InstanceMethods
        def available_filters_with_backlogs_issue_type
            @available_filters = available_filters_without_backlogs_issue_type

            if Story.trackers.length == 0 or Task.tracker.nil?
                backlogs_filters = { }
            else
                backlogs_filters = {
                        "backlogs_issue_type" => {  :type => :list,
                                                    :values => [[l(:backlogs_story), "story"], [l(:backlogs_task), "task"], [l(:backlogs_any), "any"]],
                                                    :order => 20 } 
                    }
            end

            return @available_filters.merge(backlogs_filters)
        end

        def columns_with_backlogs_story_columns
            cols = columns_without_backlogs_story_columns

            return cols if not has_default_columns?

            parentcol = available_columns.select{|c| c.name == :parent}[0]
            return cols if cols.include?(parentcol)

            return [parentcol] + cols if self.filters.has_key?("backlogs_issue_type")

            return cols
        end

        def sql_for_field_with_backlogs_issue_type(field, operator, v, db_table, db_field, is_custom_filter=false)
            if field == "backlogs_issue_type"
                db_table = Issue.table_name

                sql = []

                values_for(field).each { |val|
                    case val
                        when "story"
                            sql << "(#{db_table}.tracker_id in (" + Story.trackers.collect{|val| "#{val}"}.join(",") + ") and #{db_table}.parent_id is NULL)"
                        when "task"
                            sql << "(#{db_table}.tracker_id = #{Task.tracker} and not #{db_table}.parent_id is NULL)"
                        when "any"
                            sql << "1 = 1"
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


