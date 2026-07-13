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

module Saml
  class MetadataFetcher
    include ActionView::Helpers::NumberHelper

    def self.fetch(url, &)
      new(url).fetch(&)
    end

    def initialize(url)
      @url = url
    end

    def fetch
      Tempfile.create("saml-metadata") do |file|
        file.binmode

        OpenProject::SsrfProtection.get(@url) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            raise OneLogin::RubySaml::HttpError,
                  "Failed to fetch idp metadata: #{response.code}: #{response.message}"
          end

          bytes_written = 0
          response.read_body do |chunk|
            file.write(chunk)
            bytes_written += chunk.bytesize
            if bytes_written > MetadataDocument::MAX_SIZE
              raise MetadataDocument::MetadataTooLargeError,
                    "Metadata exceeds max size of #{number_to_human_size(MetadataDocument::MAX_SIZE, precision: 2)}"
            end
          end
        end

        file.rewind
        yield file
      end
    end
  end
end
