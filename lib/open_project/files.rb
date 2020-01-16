#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

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

    def build_uploaded_file(tempfile, type, binary: true, file_name: nil)
      uploaded_file = Rack::Multipart::UploadedFile.new tempfile.path,
                                                        type,
                                                        binary
      if file_name
        # I wish I could set the file name in a better way *sigh*
        uploaded_file.instance_variable_set(:@original_filename, file_name)
      end

      uploaded_file
    end

    def create_uploaded_file(name: 'test.txt',
                             content_type: 'text/plain',
                             content: 'test content',
                             binary: false)

      tmp = create_temp_file name: name, content: content, binary: binary
      build_uploaded_file tmp, content_type, binary: binary
    end
  end
end
