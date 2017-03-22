module OpenProject::XlsExport
  module Patches
    module WorkPackagesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        # If the index action is called, hook the xls format into the issues controller
        def respond_to(&block)
          if export_xls?
            super do |format|
              yield format

              define_xls_format! format
            end
          else
            super(&block)
          end
        end

        def export_xls?
          if action = params["action"]
            format_xls? && (action.to_sym == :index || action == "all")
          end
        end

        def format_xls?
          params["format"].to_s.downcase == "xls"
        end

        def xls_export_associations
          [:assigned_to, :type, :priority, :category, :fixed_version]
        end

        def xls_export_results(query)
          query.results include: xls_export_associations
        end

        def xls_export_filename
          FilenameHelper.sane_filename(
            "#{Setting.app_title} #{I18n.t(:label_work_package_plural)} " +
            "#{format_time_as_date(Time.now, '%Y-%m-%d')}.xls")
        end

        def define_xls_format!(format)
          format.xls do
            @work_packages = xls_export_results(@query).sorted_work_packages
            data = issues_to_xls params.slice(:show_descriptions, :show_relations)

            send_data data, type: "application/vnd.ms-excel", filename: xls_export_filename
          end
        end

        # Return an xls file from a spreadsheet builder
        def issues_to_xls(options)
          export = OpenProject::XlsExport::WorkPackageXlsExport.new(
            project: @project, work_packages: @work_packages, query: @query,
            current_user: current_user,
            with_descriptions: options[:show_descriptions],
            with_relations: options[:show_relations]
          )

          export.to_xls
        end
      end
    end
  end
end
