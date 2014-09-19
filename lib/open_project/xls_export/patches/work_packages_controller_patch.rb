module OpenProject::XlsExport
  module Patches
    module WorkPackagesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)


        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods

        # If the index action is called, hook the xls format into the issues controller
        def respond_to(&block)
          if ((params["action"] && params["action"].to_sym == :index or params[:action] == "all") && params["format"].to_s.downcase == "xls")
            super do |format|
              yield format
              format.xls do
                @issues = @query.results(:include => [:assigned_to, :type, :priority, :category, :fixed_version],
                                        :order => sort_clause).work_packages
                send_data(issues_to_xls(:show_descriptions => params[:show_descriptions]),
                          :type => "application/vnd.ms-excel",
                          :filename => FilenameHelper.sane_filename(
                            "#{Setting.app_title} #{I18n.t(:label_work_package_plural)} " +
                            "#{format_time_as_date(Time.now, '%Y-%m-%d')}.xls"))
              end
            end
          else
            super(&block)
          end
        end

        # Convert an issues query with associated issues to xls using the queries columns as headers
        def build_spreadsheet(project, issues, query, options)
          columns = query.columns

          sb = SpreadsheetBuilder.new("#{I18n.t(:label_work_package_plural)}")
          formatters = OpenProject::XlsExport::Formatters.for_columns(columns)

          headers = columns.collect(&:caption).unshift("#")
          headers << WorkPackage.human_attribute_name(:description) if options[:show_descriptions]
          sb.add_headers headers, 0

          issues.each do |work_package|
            row = (columns.collect do |column|
                    cv = formatters[column].format work_package, column
                    cv = cv.in_time_zone(current_user.time_zone) if cv.is_a?(ActiveSupport::TimeWithZone)
                    (cv.respond_to? :name) ? cv.name : cv
                  end).unshift(work_package.id)
            row << work_package.description if options[:show_descriptions]
            sb.add_row(row)
          end

          columns.each_with_index do |column, i|
            options = formatters[column].format_options column
            sb.add_format_option_to_column i + 1, options
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
