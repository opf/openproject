# frozen_string_literal: true

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

module API
  module V3
    module Utilities
      module EpropsConversion
        # Limit decompressed eprops to 10MB to prevent decompression bomb (zip bomb) attacks.
        MAX_DECOMPRESSED_SIZE = 10 * 1024 * 1024
        DECOMPRESS_CHUNK_SIZE = 16 * 1024

        def raise_invalid_eprops(error, i18n_key)
          mapped_error = ::Grape::Exceptions::Validation.new(params: [:eprops],
                                                             message: I18n.t(i18n_key, message: error.message))
          raise ::Grape::Exceptions::ValidationErrors.new(exceptions: [mapped_error])
        end

        def transform_eprops
          return unless params && params[:eprops]

          decoded = Base64.decode64(params[:eprops])
          props = ::JSON.parse(limited_inflate(decoded)).with_indifferent_access
          params.merge!(props)
        rescue Zlib::DataError => e
          raise_invalid_eprops(e, "api_v3.errors.eprops.invalid_gzip")
        rescue JSON::ParserError, NoMethodError => e
          raise_invalid_eprops(e, "api_v3.errors.eprops.invalid_json")
        end

        private

        def limited_inflate(data)
          inflater = Zlib::Inflate.new
          decompressed = +""

          begin
            pos = 0
            while pos < data.bytesize
              decompressed << inflater.inflate(data.byteslice(pos, DECOMPRESS_CHUNK_SIZE))
              pos += DECOMPRESS_CHUNK_SIZE
              if decompressed.bytesize > MAX_DECOMPRESSED_SIZE
                raise Zlib::DataError, "Decompressed data exceeds maximum allowed size (#{MAX_DECOMPRESSED_SIZE} bytes)"
              end
            end
          ensure
            inflater.close
          end

          decompressed
        end
      end
    end
  end
end
