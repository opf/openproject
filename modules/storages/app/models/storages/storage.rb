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
    self.inheritance_column = :provider_type

    store_attribute :provider_fields, :automatically_managed, :boolean
    store_attribute :provider_fields, :health_notifications_enabled, :boolean, default: true

    belongs_to :creator, class_name: "User"
    has_many :file_links, class_name: "Storages::FileLink", dependent: :destroy
    has_many :project_storages, dependent: :destroy, class_name: "Storages::ProjectStorage"
    has_many :projects, through: :project_storages
    has_one :oauth_client, as: :integration, dependent: :destroy
    has_one :oauth_application, class_name: "::Doorkeeper::Application", as: :integration, dependent: :destroy
    has_many :remote_identities, as: :integration, dependent: :destroy
    has_many :health_reports, as: :subject, dependent: :delete_all

    validates :host, uniqueness: { allow_nil: true }
    validates :name, uniqueness: { case_sensitive: false }

    scope :visible, lambda { |user = User.current|
      if user.admin? || user.allowed_in_any_project?(:manage_files_in_project)
        all
      else
        where(project_storages: ProjectStorage.where(project: Project.allowed_to(user, :view_file_links)))
      end
    }

    scope :not_enabled_for_project, ->(project) { where.not(id: project.project_storages.pluck(:storage_id)) }

    scope :automatic_management_enabled, -> { where("provider_fields->>'automatically_managed' = 'true'") }

    scope :in_project, ->(project_id) { joins(project_storages: :project).where(project_storages: { project_id: }) }

    scope :with_audience, ->(audience) { where("provider_fields->>'storage_audience' = ?", audience) }

    enum :health_status, {
      pending: "pending",
      healthy: "healthy",
      unhealthy: "unhealthy"
    }, prefix: :health

    class << self
      def visible? = true

      def provider_types
        subclasses.sort_by(&:name) # Guarantees alphabetical ordering
                  .filter_map { [it.short_provider_name, it] if it.visible? } # Remove non-exposed providers
                  .to_h.with_indifferent_access
      end

      def short_provider_name = raise SubclassResponsibilityError

      def allowed_by_enterprise_token? = true

      def disallowed_by_enterprise_token? = !allowed_by_enterprise_token?

      # TODO: Compatibility Method To be Removed once all references are removed - 2025-07-14 @mereghost
      def shorten_provider_type(provider_type)
        provider_type.constantize.short_provider_name.to_s
      end

      def extract_part_from_piped_string(text, index)
        return if text.nil?

        split_reason = text.split(/[|:]/)
        split_reason[index].strip if split_reason.length > index
      end

      def non_confidential_provider_fields
        %i[automatically_managed health_notifications_enabled]
      end
    end

    delegate :short_provider_name, :allowed_by_enterprise_token?, :disallowed_by_enterprise_token?, to: :class
    delegate :to_s, to: :short_provider_name
    alias :short_provider_type :to_s

    def oauth_access_granted?(user)
      (user.authentication_provider.is_a?(OpenIDConnect::Provider) && authenticate_via_idp?) ||
        OAuthClientToken.exists?(user:, oauth_client:)
    end

    # For the time being, all Storages support OAuth redirect.
    # If a storage does not support OAuth redirect, it should override this method.
    def supports_oauth_redirect?
      true
    end

    def health_notifications_should_be_sent?
      # it is a fallback for already created storages without health_notifications_enabled configured.
      (health_notifications_enabled.nil? && automatic_management_enabled?) || health_notifications_enabled?
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

    def available_project_folder_modes = raise SubclassResponsibilityError

    # Returns a value of an audience, if configured for this storage.
    # The presence of an audience signals that this storage prioritizes
    # remote authentication via Single-Sign-On if possible.
    def audience = raise SubclassResponsibilityError

    def authenticate_via_idp? = raise SubclassResponsibilityError

    def authenticate_via_storage? = raise SubclassResponsibilityError

    def configured? = configuration_checks.values.all?

    def configuration_checks = raise SubclassResponsibilityError

    def skip_client_secret_validation? = false

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

    def oauth_configuration = raise SubclassResponsibilityError

    def automatic_management_new_record? = raise SubclassResponsibilityError

    def provider_fields_defaults = raise SubclassResponsibilityError

    def non_confidential_configuration
      provider_fields.symbolize_keys
                     .slice(*self.class.non_confidential_provider_fields)
                     .merge(
                       host:,
                       oauth_client_id: oauth_client&.client_id,
                       oauth_application_client_id: oauth_application&.uid
                     )
    end

    def provider_type_nextcloud?
      is_a?(NextcloudStorage)
    end

    def provider_type_one_drive?
      is_a?(OneDriveStorage)
    end

    def provider_type_share_point?
      is_a?(SharepointStorage)
    end

    def health_reason_identifier
      @health_reason_identifier ||= self.class.extract_part_from_piped_string(health_reason, 0)
    end

    def health_reason_description
      @health_reason_description ||= self.class.extract_part_from_piped_string(health_reason, 1)
    end

    def extract_origin_user_id(token)
      auth_strategy = Adapters::Input::Strategy.build(key: :bearer_token, token: token.access_token)
      Adapters::Registry.resolve("#{self}.queries.user").call(auth_strategy:, storage: self).fmap { it[:id] }
    end

    def typed_label
      type = I18n.t("storages.provider_types.#{short_provider_name}.name")
      "#{name} (#{type})"
    end
  end
end
