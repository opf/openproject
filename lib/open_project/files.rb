#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Files
    module_function

    def build_uploaded_file(tempfile, type, binary: true, file_name: nil)
      Rack::Multipart::UploadedFile.new tempfile.path,
                                        type,
                                        binary,
                                        filename: file_name
    end

    def create_uploaded_file(name:, content_type:, content:, binary: false)
      create_temp_file(name:, content:, binary:) do |f|
        build_uploaded_file f, content_type, binary:, file_name: File.basename(name)
      end
    end

    def create_temp_file(name:, content:, binary: false, &)
      basename = name
      Tempfile.create(basename) do |f|
        f.binmode if binary

        f.write content
        f.rewind

        yield f
      end
    end
  end
end
