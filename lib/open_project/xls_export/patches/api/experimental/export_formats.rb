module OpenProject
  module XlsExport
    ##
    # Mix into Api::Experimental::WorkPackagesController to add
    # the XLS export formats to the export dialog of the core.
    module ExportFormats
      def export_formats
        formats = xls_export_formats.reject do |entry|
          xls_export_disabled_formats.any? { |f| entry[:label_locale] =~ /#{f}$/}
        end

        super + formats
      end

      module_function

      ##
      # Supported values are:
      #   - xls
      #   - xls_with_descriptions
      #   - xls_with_relations
      def xls_export_disabled_formats
        Array(Hash(OpenProject::Configuration['xls_export'])['disabled_formats'])
      end

      ##
      # Note: identifier is used to construct the CSS class of the menu entry which
      #       is relevant for the used icon.
      def xls_export_formats
        [
          { identifier: 'xls', format: 'xls', label_locale: 'label_format_xls' },
          {
            identifier: 'xls-descr', format: 'xls',
            label_locale: 'label_format_xls_with_descriptions', flags: ['show_descriptions']
          },
          {
            identifier: 'xls', format: 'xls',
            label_locale: 'label_format_xls_with_relations', flags: ['show_relations']
          }
        ]
      end
    end
  end
end
