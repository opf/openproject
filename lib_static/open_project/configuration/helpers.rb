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
  module Configuration
    ##
    # To be included into OpenProject::Configuration in order to provide
    # helper methods for easier access to certain configuration options.
    module Helpers
      def direct_uploads
        return false unless direct_uploads_supported?

        self["direct_uploads"]
      end

      ##
      # Is hsts really enabled? We only return true
      # if the setting is true AND HTTPS mode is on.
      def hsts_enabled?
        https? && hsts?
      end

      ##
      # We only allow direct uploads to S3 as we are using the carrierwave_direct
      # gem which only supports S3 for the time being.
      #
      # Do not allow direct uploads when using IAM-profile-based authorization rather
      # than access-key-based ones since carrierwave_direct does not support that.
      #
      # We do support direct uploads for S3-compatible object storage services
      # only if remote storage upload and download hosts were configured explicitly.
      # Since these only have to be configured if you want to use direct uploads,
      # we assume what ever provider you use does support this if you do.
      def direct_uploads_supported?
        remote_storage? && remote_storage_aws? && !use_iam_profile? &&
          (using_amazon_s3? || using_custom_remote_storage_hosts?)
      end

      def using_amazon_s3?
        fog_credentials[:host].blank?
      end

      def using_custom_remote_storage_hosts?
        self["remote_storage_upload_host"].present? && self["remote_storage_download_host"].present?
      end

      def direct_uploads?
        direct_uploads
      end

      # Augur connect host
      def enterprise_trial_creation_host
        if Rails.env.production?
          self["enterprise_trial_creation_host"]
        else
          "https://start.openproject-edge.com"
        end
      end

      def file_storage?
        attachments_storage == :file
      end

      def remote_storage?
        attachments_storage == :fog
      end

      def remote_storage_aws?
        fog_credentials[:provider] == "AWS"
      end

      def remote_storage_upload_host
        self["remote_storage_upload_host"].presence ||
          (remote_storage_aws? && "#{fog_directory}.s3.amazonaws.com") ||
          nil
      end

      def remote_storage_download_host
        self["remote_storage_download_host"].presence ||
          (remote_storage_aws? && "#{fog_directory}.s3.#{fog_credentials[:region]}.amazonaws.com") ||
          nil
      end

      def remote_storage_hosts
        [
          fog_credentials[:host],
          remote_storage_upload_host,
          remote_storage_download_host
        ].compact
      end

      def attachments_storage_path
        Rails.root.join(self["attachments_storage_path"] || "files")
      end

      def use_iam_profile?
        fog_credentials[:use_iam_profile]
      end

      def fog_credentials
        (Hash(self["fog"])["credentials"] || {}).map { |key, value| [key.to_sym, value] }.to_h
      end

      def fog_directory
        Hash(self["fog"])["directory"]
      end

      def file_uploader
        available_file_uploaders[OpenProject::Configuration.attachments_storage.to_sym]
      end

      def hidden_menu_items
        menus = self["hidden_menu_items"].map do |label, nodes|
          [label, array(nodes)]
        end

        menus.to_h
      end

      ##
      # Whether we're running a bim edition
      def bim?
        self["edition"] == "bim"
      end

      def available_file_uploaders
        uploaders = {
          file: ::LocalFileUploader
        }

        # Do not load Fog uploader unless configured,
        # it will fail with missing configuration
        unless OpenProject::Configuration.fog_credentials.empty?
          uploaders[:fog] = "::FogFileUploader".constantize
        end

        uploaders
      end

      def web_workers
        Integer(web["workers"].presence)
      end

      def web_timeout
        Integer(ENV["RACK_TIMEOUT_SERVICE_TIMEOUT"].presence || web["timeout"].presence)
      end

      def web_wait_timeout
        Integer(ENV["RACK_TIMEOUT_WAIT_TIMEOUT"].presence || web["wait_timeout"].presence)
      end

      def web_min_threads
        Integer(ENV["RAILS_MIN_THREADS"].presence || web["min_threads"].presence)
      end

      def web_max_threads
        Integer(ENV["RAILS_MAX_THREADS"].presence || web["max_threads"].presence)
      end

      def statsd_host
        ENV["STATSD_HOST"].presence || statsd["host"].presence
      end

      def statsd_port
        Integer(ENV["STATSD_PORT"].presence || statsd["port"].presence)
      end

      def lookbook_enabled?
        self["lookbook_enabled"]
      end

      private

      ##
      # Yields the given configuration value as an array.
      # Either the value already is an array or a string with values separated by spaces.
      # In the latter case the string will be split and the values returned as an array.
      def array(value)
        if value.is_a?(String) && value.include?(" ")
          value.split
        else
          Array(value)
        end
      end
    end
  end
end
