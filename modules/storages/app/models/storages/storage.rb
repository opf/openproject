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
      PROVIDER_TYPE_NEXTCLOUD = "Storages::NextcloudStorage",
      PROVIDER_TYPE_ONE_DRIVE = "Storages::OneDriveStorage"
    ].freeze

    PROVIDER_TYPE_SHORT_NAMES = {
      nextcloud: PROVIDER_TYPE_NEXTCLOUD,
      one_drive: PROVIDER_TYPE_ONE_DRIVE
    }.with_indifferent_access.freeze

    self.inheritance_column = :provider_type

    store_attribute :provider_fields, :automatically_managed, :boolean
    store_attribute :provider_fields, :health_notifications_enabled, :boolean, default: true

    has_many :file_links, class_name: "Storages::FileLink"
    belongs_to :creator, class_name: "User"
    has_many :project_storages, dependent: :destroy, class_name: "Storages::ProjectStorage"
    has_many :projects, through: :project_storages
    has_one :oauth_client, as: :integration, dependent: :destroy
    has_one :oauth_application, class_name: "::Doorkeeper::Application", as: :integration, dependent: :destroy

    validates_uniqueness_of :host, allow_nil: true
    validates_uniqueness_of :name

    scope :visible, ->(user = User.current) do
      if user.allowed_in_any_project?(:manage_files_in_project)
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

    scope :automatic_management_enabled, -> { where("provider_fields->>'automatically_managed' = 'true'") }

    scope :in_project, ->(project_id) { joins(project_storages: :project).where(project_storages: { project_id: }) }

    enum health_status: {
      pending: "pending",
      healthy: "healthy",
      unhealthy: "unhealthy"
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

      split_reason = text.split(/[|:]/)
      if split_reason.length > index
        split_reason[index].strip
      end
    end

    def health_notifications_should_be_sent?
      # it is a fallback for already created storages without health_notifications_enabled configured.
      (health_notifications_enabled.nil? && automatic_management_enabled?) || health_notifications_enabled?
    end

    def automatically_managed?
      ActiveSupport::Deprecation.warn(
        "`#automatically_managed?` is deprecated. Use `#automatic_management_enabled?` instead. " \
        "NOTE: The new method name better reflects the actual behavior of the storage. " \
        "It's not the storage that is automatically managed, rather the Project (Storage) Folder is. " \
        "A storage only has this feature enabled or disabled."
      )
      super
    end

    def automatic_management_enabled?
      !!automatically_managed
    end

    def automatic_management_unspecified?
      automatically_managed.nil?
    end

    def automatic_management_enabled=(value)
      self.automatically_managed = value
    end

    alias automatic_management_enabled automatically_managed

    def available_project_folder_modes
      raise Errors::SubclassResponsibility
    end

    def configured?
      configuration_checks.values.all?
    end

    def configuration_checks
      raise Errors::SubclassResponsibility
    end

    def uri
      return unless host

      @uri ||= if host.end_with?("/")
                 URI(host).normalize
               else
                 URI("#{host}/").normalize
               end
    end

    def connect_src
      port_part = [80, 443].include?(uri.port) ? "" : ":#{uri.port}"
      ["#{uri.scheme}://#{uri.host}#{port_part}"]
    end

    def oauth_configuration
      raise Errors::SubclassResponsibility
    end

    def automatic_management_new_record?
      raise Errors::SubclassResponsibility
    end

    def provider_fields_defaults
      raise Errors::SubclassResponsibility
    end

    def short_provider_type
      @short_provider_type ||= self.class.shorten_provider_type(provider_type)
    end

    def to_s
      short_provider_type
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
  end
end
