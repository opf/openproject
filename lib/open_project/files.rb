module OpenProject
  module Files
    module_function

    ##
    # Creates a temp file with the given file name.
    # It will reside in some temporary directory.
    def create_temp_file(name: 'test.txt', content: 'test content', binary: false)
      tmp = Tempfile.new name
      path = Pathname(tmp)

      tmp.delete # delete temp file
      path.mkdir # create temp directory

      file_path = path.join name
      File.open(file_path, 'w' + (binary ? 'b' : '')) do |f|
        f.write content
      end

      File.new file_path
    end

    def create_uploaded_file(name: 'test.txt',
                             content_type: 'text/plain',
                             content: 'test content',
                             binary: false)

      tmp = create_temp_file name: name, content: content, binary: binary
      Rack::Multipart::UploadedFile.new tmp.path, content_type, binary
    end
  end
end
