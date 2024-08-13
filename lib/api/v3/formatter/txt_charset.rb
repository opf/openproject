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

module API::V3::Formatter
  class TxtCharset
    def self.call(object, env)
      encoding = encoding(object, env)

      object.force_encoding(encoding)
    end

    # Returns the encoding of
    # * the content type (charset) if provided and valid or
    # * the objects encoding if provided and invalid
    # * Encoding.default_external if no charset provided
    def self.encoding(object, env)
      Encoding.find(charset(env))
    rescue StandardError
      object.encoding
    end
    private_class_method :encoding

    # Detects the charset in the content_type header.
    # If no charset is defined, the default_external encoding is assumed.
    #
    # This might return an invalid charset as only pattern matching is applied.
    def self.charset(env)
      content_type = env["CONTENT_TYPE"].to_s

      if (matches = content_type.match(/charset=([^\s;]+)/))
        matches[1]
      else
        Encoding.default_external
      end
    end
    private_class_method :charset
  end
end
