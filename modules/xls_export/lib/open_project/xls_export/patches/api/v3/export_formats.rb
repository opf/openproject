module OpenProject::XlsExport::Patches
  module API::V3::ExportFormats
    def representation_formats
      super + [
        representation_format_xls,
        representation_format_xls_descriptions,
        representation_format_xls_relations
      ]
    end

    def representation_format_xls
      representation_format 'xls',
                            mime_type: 'application/vnd.ms-excel'
    end

    def representation_format_xls_descriptions
      representation_format 'xls-with-descriptions',
                            i18n_key: 'xls_with_descriptions',
                            mime_type: 'application/vnd.ms-excel',
                            format: 'xls',
                            url_query_extras: 'show_descriptions=true'
    end

    def representation_format_xls_relations
      representation_format 'xls-with-relations',
                            i18n_key: 'xls_with_relations',
                            mime_type: 'application/vnd.ms-excel',
                            format: 'xls',
                            url_query_extras: 'show_relations=true'
    end
  end
end
