module OpenProject::Bcf::Patches
  module Api::V3::ExportFormats
    def representation_formats
      super + [representation_format_bcf]
    end

    def representation_format_bcf
      representation_format :bcf,
                            mime_type: 'application/octet-stream'
    end
  end
end
