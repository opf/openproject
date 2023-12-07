# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# A "Storage" refers to some external source where files are stored.
# The first supported storage is Nextcloud (www.nextcloud.com).
# a Storage is mainly defined by a name, a "provider_type" (i.e.
# Nextcloud or something similar) and a "host" URL.
#
# Purpose: The code below is a standard Ruby model:
# https://guides.rubyonrails.org/active_model_basics.html
# It defines defines checks and permissions on the Ruby level.
# Additional attributes and constraints are defined in
# db/migrate/20220113144323_create_storage.rb "migration".
module Storages
  class Storage < ApplicationRecord
    PROVIDER_TYPES = [
      PROVIDER_TYPE_NEXTCLOUD = 'Storages::NextcloudStorage',
      PROVIDER_TYPE_ONE_DRIVE = 'Storages::OneDriveStorage'
    ].freeze

    PROVIDER_TYPE_SHORT_NAMES = {
      nextcloud: PROVIDER_TYPE_NEXTCLOUD,
      one_drive: PROVIDER_TYPE_ONE_DRIVE
    }.with_indifferent_access.freeze

    self.inheritance_column = :provider_type

    has_many :file_links, class_name: 'Storages::FileLink'
    belongs_to :creator, class_name: 'User'
    has_many :project_storages, dependent: :destroy, class_name: 'Storages::ProjectStorage'
    has_many :projects, through: :project_storages
    has_one :oauth_client, as: :integration, dependent: :destroy
    has_one :oauth_application, class_name: '::Doorkeeper::Application', as: :integration, dependent: :destroy

    validates_uniqueness_of :host, allow_nil: true
    validates_uniqueness_of :name

    scope :visible, ->(user = User.current) do
      if user.allowed_in_any_project?(:manage_storages_in_project)
        all
      else
        where(
          project_storages: ::Storages::ProjectStorage.where(
            project: Project.allowed_to(user, :view_file_links)
          )
        )
      end
    end

    scope :not_enabled_for_project, ->(project) do
      where.not(id: project.project_storages.pluck(:storage_id))
    end

    enum health_status: {
      pending: 'pending',
      healthy: 'healthy',
      unhealthy: 'unhealthy'
    }.freeze, _prefix: :health

    def self.shorten_provider_type(provider_type)
      case /Storages::(?'provider_name'.*)Storage/.match(provider_type)
      in provider_name:
        provider_name.underscore
      else
        raise ArgumentError,
              "Unknown provider_type! Given: #{provider_type}. " \
              "Expected the following signature: Storages::{Name of the provider}Storage"
      end
    end

    def self.one_drive_without_ee_token?(provider_type)
      provider_type == ::Storages::Storage::PROVIDER_TYPE_ONE_DRIVE &&
        !EnterpriseToken.allows_to?(:one_drive_sharepoint_file_storage)
    end

    def self.extract_part_from_piped_string(text, index)
      return if text.nil?

      split_reason = text.split('|')
      if split_reason.length > index
        split_reason[index].strip
      end
    end

    def mark_as_unhealthy(reason: nil)
      reason = forward_or_add_health_reason_since_time(reason.to_s) unless reason.nil?
      update(health_status: 'unhealthy', health_changed_at: Time.now.utc, health_reason: reason)
    end

    def mark_as_healthy
      update(health_status: 'healthy', health_changed_at: Time.now.utc, health_reason: nil)
    end

    def configured?
      configuration_checks.values.all?
    end

    def configuration_checks
      raise Errors::SubclassResponsibility
    end

    def uri
      return unless host

      @uri ||= URI(host).normalize
    end

    def connect_src
      ["#{uri.scheme}://#{uri.host}"]
    end

    def oauth_configuration
      raise Errors::SubclassResponsibility
    end

    def short_provider_type
      @short_provider_type ||= self.class.shorten_provider_type(provider_type)
    end

    def provider_type_nextcloud?
      provider_type == ::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD
    end

    def provider_type_one_drive?
      provider_type == ::Storages::Storage::PROVIDER_TYPE_ONE_DRIVE
    end

    def health_reason_identifier
      @health_reason_identifier ||= self.class.extract_part_from_piped_string(health_reason, 0)
    end

    def health_reason_description
      @health_reason_description ||= self.class.extract_part_from_piped_string(health_reason, 1)
    end

    def health_reason_since_time
      @health_reason_since_time ||= self.class.extract_part_from_piped_string(health_reason, 3)
    end

    private

    # The error messages from the ServiceResult look like:
    # "unauthorized | Outbound request not authorized | #<Storages::StorageErrorData:0x0000ffff646ac570>"
    # This method adds the Time.now.utc when the error occurs the first time and forwards it subsequently till the
    # error identifier changes.
    def forward_or_add_health_reason_since_time(new_health_reason)
      if health_reason_since_time && health_reason_identifier == self.class.extract_part_from_piped_string(new_health_reason, 0)
        "#{new_health_reason} | #{ health_reason_since_time }"
      else
        "#{new_health_reason} | #{ Time.now.utc }"
      end
    end
  end
end
