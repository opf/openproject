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
module Storages::Admin
  class RedirectUriComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include StorageViewInformation

    attr_reader :storage
    alias_method :oauth_client, :model

    def initialize(oauth_client:, storage:, **)
      super(oauth_client, **)
      @storage = storage
    end

    def self.wrapper_key = :storage_redirect_uri_section

    def show_icon_button_options
      {
        icon: :eye,
        tag: :a,
        href: url_helpers.show_redirect_uri_admin_settings_storage_oauth_client_path(storage),
        scheme: :invisible,
        aria: { label: I18n.t("storages.label_show_storage_redirect_uri") },
        test_selector: "storage-show-redirect-uri-button"
      }
    end
  end
end
