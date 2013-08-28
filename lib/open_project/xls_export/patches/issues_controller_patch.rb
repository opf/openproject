#require_dependency 'issues_controller'
#require_dependency 'xls_report/spreadsheet_builder'
#require_dependency 'additional_formats/filter_settings_helper'

module OpenProject::XlsExport
  module Patches
    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods

        # If the index action is called, hook the xls format into the issues controller
        def respond_to(&block)
          if ((params["action"].to_sym == :index or params[:action] == "all") && params["format"].to_s.downcase == "xls")
            super do |format|
              yield format
              format.xls do
                @issues = @query.issues(:include => [:assigned_to, :type, :priority, :category, :fixed_version],
                                        :order => sort_clause)
                unless @issues.empty?
                  send_data(issues_to_xls(:show_descriptions => params[:show_descriptions]),
                            :type => "application/vnd.ms-excel",
                            :filename => FilenameHelper.sane_filename(
                              "#{Setting.app_title} #{I18n.t(:label_work_package_plural)} " +
                              "#{format_time_as_date(Time.now, '%Y-%m-%d')}.xls"))
                end
              end
            end
          else
            super(&block)
          end
        end

        # Convert an issues query with associated issues to xls using the queries columns as headers
        def build_spreadsheet(project, issues, query, options)
          columns = query.columns

          sb = SpreadsheetBuilder.new
          project_name = (project.name if project) || "All Projects"
          sb.add_title("#{project_name} >> #{l(:label_issue_plural)} (#{format_date(Date.today)})")

          filters = FilterSettingsHelper.filter_settings(query)
          sb.add_headers [l(:label_filter_plural)]
          sb.add_row(filters)
          group_by_settings = FilterSettingsHelper.group_by_setting(query)
          if group_by_settings
            sb.add_headers [Query.human_attribute_name(:group_by)]
            sb.add_row [group_by_settings]
          end
          sb.add_empty_row

          headers = columns.collect(&:caption).unshift("#")
          headers << Issue.human_attribute_name(:description) if options[:show_descriptions]
          sb.add_headers headers

          issues.each do |issue|
            row = (columns.collect do |column|
                    cv = column.value(issue)
                    (cv.respond_to? :name) ? cv.name : cv
                  end).unshift(issue.id)
            row << issue.description if options[:show_descriptions]
            sb.add_row(row)
          end

          headers.each_with_index do |h,idx|
            h = h.to_s.downcase
            if (h =~ /.*hours.*/ or h == "spent_time")
              sb.add_format_option_to_column idx, :number_format => "0.0 h"
            elsif (h =~ /.*cost.*/)
              sb.add_format_option_to_column idx, :number_format => number_to_currency(0.00)
            end
          end

          sb
        end

        # Return an xls file from a spreadsheet builder
        def issues_to_xls(options)
          build_spreadsheet(@project, @issues, @query, options).xls
        end
      end
    end
  end
end
