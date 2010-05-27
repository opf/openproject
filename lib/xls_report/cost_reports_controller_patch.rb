# Only apply this patch if the redmine_costs plugin is available
if require_dependency 'cost_reports_controller'
  require_dependency 'xls_report/spreadsheet_builder'
  
  module XlsReport
    module CostReportsControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
    
        base.class_eval do
          unloadable
        end
      end
    
      module InstanceMethods
      
        # If the index action is called, hook the xls format into the cost report
        def respond_to(&block)
          if (params["action"].to_sym == :index && params["format"].to_s.downcase == "xls")
            super do |format|
              yield format
              format.xls do
                send_data(report_to_xls, :type => :xls, 
                  :filename => FilenameHelper.sane_filename("(#{I18n.l(DateTime.now)}) Cost Report#{" " + @project.name if @project}.xls"))
              end
            end
          else
            super(&block)
          end
        end
        
        # Build an xls file from a cost report. Uses all headers displayed for now, as there are no
        # options for this atm.
        # --
        # FIXME: Rework this when the query branch is merged
        def report_to_xls
          sb = SpreadsheetBuilder.new
          sb.add_title("#{@project.name} >> #{l(:cost_reports_title)} (#{format_date(Date.today)})")
          
          unless @grouped_entries
            entry_header = [l(:caption_spent),
                            l(:label_user), 
                            l(:label_activity), 
                            l(:caption_issue), 
                            l(:field_comments), 
                            l(:caption_cost_unit_plural), 
                            l(:caption_cost_type), 
                            l(:caption_costs)]
            sb.add_headers entry_header
            sb.add_format_option_to_column 0, :number_format => "0.00"
            sb.add_format_option_to_column 7, :number_format => number_to_currency(0.00)
            @entries.each do |entry|
              entry_fields = [entry.spent_on,
                              entry.user.name, 
                              entry.is_a?(TimeEntry) ? (entry.activity && entry.activity.name) : "",
                              entry.issue ? entry.issue_id : "",
                              entry.comments,
                              if entry.is_a?(CostEntry)
                                entry.units
                              elsif entry.is_a?(TimeEntry)
                                entry.hours
                              end,
                              entry.is_a?(CostEntry) ? entry.cost_type.name : l(:caption_labor_costs),
                              entry.display_costs ? entry.real_costs.to_f : ""]
              sb.add_row entry_fields
            end
          else
            group_by_column = CostQuery.group_by_columns[@query.group_by[:name]]
            display_costs = CostEntry.column_names.include?([:db_field].to_s) && @query.display_cost_entries
            
            sb.add_headers ["Group By",
                            "Count",
                            if (@query.group_by["name"] == "cost_type_id") || (!display_costs)
                              l(:caption_cost_unit_plural)
                            end,
                            "Sum"].compact
            sb.add_format_option_to_column 1, :number_format => "0"
            sb.add_format_option_to_column 2, :number_format => "0#{t(:number)[:format][:separator]}00"
            sb.add_format_option_to_column 3, :number_format => "0#{t(:number)[:format][:separator]}00"
            if (@query.group_by["name"] == "cost_type_id") || (!display_costs)
              sb.add_format_option_to_column 4, :number_format => "0#{t(:number)[:format][:separator]}00"
            end
            
            @grouped_entries.each do |entry|
              entry &&= entry.with_indifferent_access
              
              fields = entry.keys - %w[count sum unit_sum]
              if fields.include? "tmonth"
                name = "#{entry[:tyear]}, #{month_name(entry["tmonth"].to_i)}"
              elsif fields.include? "tweek"
                name = "#{entry[:tyear]}, #{l(:week)} \##{entry["tweek"]}"
              else
                name = fields.map { |k| CostQuery.get_name(k, entry[k]) }.join " "
              end
              name.strip!
              
              sb.add_row [name,
                          entry["count"].to_i,
                          if (@query.group_by["name"] == "cost_type_id") || (!display_costs)
                            cost_type = CostType.find_by_id(entry["cost_type_id"])
                            (entry["unit_sum"] || 0).to_f
                          end,
                          entry["sum"].to_f].compact
            end
          end
          sb.xls
        end
      end
    end
  end
  
  CostReportsController.send(:include, XlsReport::CostReportsControllerPatch)
end
