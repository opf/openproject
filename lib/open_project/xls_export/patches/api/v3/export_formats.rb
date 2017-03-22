module OpenProject::XlsExport::Patches
  module Api::V3::ExportFormats
    def representation_formats
      super + [
        representation_format_xls,
        representation_format_xls_descriptions,
        representation_format_xls_relations
      ]
    end

    def representation_format_xls
      representation_format('xls',
                            'application/vnd.ms-excel')
    end

    def representation_format_xls_descriptions
      representation_format('xls',
                            'application/vnd.ms-excel',
                            'xls_with_descriptions',
                            'show_descriptions=true')
    end

    def representation_format_xls_relations
      representation_format('xls',
                            'application/vnd.ms-excel',
                            'xls_with_relations',
                            'show_relations=true')
    end
  end
end
