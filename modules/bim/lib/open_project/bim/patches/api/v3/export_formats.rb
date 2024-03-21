module OpenProject::Bim::Patches
  module API::V3::ExportFormats
    def representation_formats
      if OpenProject::Configuration.bim?
        super + [representation_format_bcf]
      else
        super
      end
    end

    def representation_format_bcf
      representation_format :bcf,
                            mime_type: 'application/octet-stream'
    end
  end
end
