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
#
module Storages::Admin::Forms
  class RedirectUriFormComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    attr_reader :storage
    alias_method :oauth_client, :model

    def initialize(oauth_client:, storage:, **)
      super(oauth_client, **)
      @storage = storage
    end

    def self.wrapper_key = :storage_redirect_uri_section

    def cancel_button_path
      storage.persisted? ? edit_admin_settings_storage_path(storage) : admin_settings_storages_path
    end

    def submit_button_disabled?
      !oauth_client_configured?
    end

    def redirect_uri_or_instructions
      if oauth_client_configured?
        oauth_client.redirect_uri
      else
        I18n.t("storages.instructions.one_drive.missing_client_id_for_redirect_uri")
      end
    end

    private

    def oauth_client_configured?
      oauth_client.present? && oauth_client.client_id.present? && oauth_client.client_secret.present?
    end
  end
end
