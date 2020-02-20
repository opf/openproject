##
# Helper class to provide uploads from IO streams.
module OpenProject::Bim::BcfXml
  class FileEntry < StringIO
    def initialize(stream, filename:)
      super(stream.read)
      @original_filename = filename
    end

    attr_reader :original_filename
    alias :path :original_filename
  end
end
