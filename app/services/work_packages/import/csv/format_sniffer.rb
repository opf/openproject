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

module WorkPackages
  module Import
    module CSV
      # The browser-supplied content type is never consulted. Browsers report a .csv as
      # text/csv, application/vnd.ms-excel or text/plain.
      class FormatSniffer
        # A CSV of plain ASCII is reported as us-ascii rather than utf-8, and is valid utf-8
        ACCEPTED_CHARSETS = %w[utf-8 us-ascii].freeze

        # @param file [String, Pathname, #path] the uploaded file, or its path
        # @return [ServiceResult] failure carries :unknown in +result+
        def self.call(file) = new(file).call

        def initialize(file)
          @file = file
        end

        def call
          return ServiceResult.success if empty? || accepted_charset?

          ServiceResult.failure(result: :unknown, message:)
        end

        def detected = @detected ||= OpenProject::ContentTypeDetector.new(path).detect_with_charset

        private

        attr_reader :file

        def content_type = detected.first

        def charset = detected.last

        def path = file.respond_to?(:path) ? file.path : file.to_s

        def empty? = content_type == OpenProject::ContentTypeDetector::EMPTY_TYPE

        def accepted_charset? = ACCEPTED_CHARSETS.include?(charset)

        def message
          if charset
            I18n.t("work_packages.import.csv.format.wrong_encoding", encoding: charset.upcase)
          else
            I18n.t("work_packages.import.csv.format.unknown")
          end
        end
      end
    end
  end
end
