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
    include GoodJob::ActiveJobExtensions::Concurrency

    # RootSeeder wraps seeding in a single transaction.
    # At the same time, CarrierWave only actually _saves_ the file in an after_commit callback.
    # Rails will however only run after_commit callbacks on the last instance to save a given row.
    # Since introduction of this job, we are now saving multiple times, so some uploads were lost.
    # By enqueueing the job after the transaction commit, we ensure that the file is saved to fog/disk.
    self.enqueue_after_transaction_commit = true

    # Only one asset for a given CustomStyle may be stored at a time. During seed,
    # GoodJob runs inline so jobs are mostly serial already, but retries and
    # non-inline enqueues could create a race condition for the same record/fog uploads.
    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "#{self.class.name}-#{arguments.first.id}" }
    )

    # ActiveJob matches retry_on/discard_on from bottom to top, so declare the
    # broad StandardError handler first and more specific handlers after it.
    retry_on StandardError, wait: :polynomially_longer, attempts: 5, report: true do |job, error|
      job.log_discard(error)
    end

    retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
             wait: 5.seconds,
             attempts: :unlimited

    discard_on ActiveJob::DeserializationError do |job, error|
      job.log_discard(error)
    end

    discard_on OpenProject::ServerSideRequestForgeryError do |job, error|
      job.log_discard(error)
    end

    queue_with_priority :low

    def perform(custom_style, key, url)
      download(custom_style, key, url)

      Rails.logger.info "Seeded design asset '#{key}' from #{url}."
    rescue OpenProject::ServerSideRequestForgeryError, ActiveJob::DeserializationError
      raise
    rescue StandardError => e
      log_attempt_failure(key, url, e)
      raise
    end

    def log_discard(error)
      _custom_style, key, url = arguments
      Rails.logger.error "Discarding design asset seed for '#{key}' from #{url} " \
                         "after #{executions} attempt(s): #{error.message}"
    end

    private

    def download(custom_style, key, url)
      response = OpenProject.httpx.get(url)
      response.raise_for_status

      style = store_asset(custom_style, key, response.body.to_s)
      ensure_readable!(style, key)
    end

    def store_asset(custom_style, key, data)
      CustomStyle.transaction do
        style = CustomStyle.lock.find(custom_style.id)

        build_attachable_file(key.to_s, data) do |file|
          style.public_send("#{key}=", file)
          style.save!

          # CarrierWave only uploads in after_commit. Inside RootSeeder's transaction,
          # Rails runs those callbacks on only one AR instance of this row, so force
          # the upload now
          style.public_send(:"store_#{key}!")
        end

        style
      end
    end

    def ensure_readable!(style, key)
      return if style.public_send(key).readable?

      raise "Stored design asset '#{key}' is not readable in file storage"
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

    def log_attempt_failure(key, url, error)
      Rails.logger.error "Failed to seed design asset '#{key}' from #{url} " \
                         "on attempt #{executions}: #{error.message}"
    end
  end
end
