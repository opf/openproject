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

module CustomStyles
  # Downloads a design asset seeded through OPENPROJECT_SEED_DESIGN_* as a remote URL.
  class SeedRemoteAssetJob < ApplicationJob
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    # Declared after retry_on StandardError so they take precedence
    discard_on ActiveJob::DeserializationError
    discard_on OpenProject::ServerSideRequestForgeryError

    queue_with_priority :low

    def perform(custom_style, key, url)
      download(custom_style, key, url)

      Rails.logger.info "Seeded design asset '#{key}' from #{url}."
    rescue StandardError => e
      Rails.logger.error "Failed to seed design asset '#{key}' from #{url} " \
                         "on attempt #{executions}: #{e.message}"
      raise
    end

    private

    def download(custom_style, key, url)
      response = OpenProject.httpx.get(url)
      response.raise_for_status

      build_attachable_file(key.to_s, response.body.to_s) do |file|
        custom_style.public_send("#{key}=", file)
        custom_style.save!
      end
    end

    def build_attachable_file(file_name, data)
      Tempfile.open(file_name) do |tempfile|
        tempfile.binmode
        tempfile.write(data)
        tempfile.rewind

        content_type = OpenProject::ContentTypeDetector.new(tempfile.path).detect
        mime_type = MIME::Types[content_type].first
        raise ArgumentError, "Unknown mime type: #{content_type}" if mime_type.nil?

        file = OpenProject::Files.build_uploaded_file(tempfile,
                                                      content_type,
                                                      file_name: "#{file_name}.#{mime_type.preferred_extension}")

        yield(file)
      end
    end
  end
end
