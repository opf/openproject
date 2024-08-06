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
  class OAuthApplicationInfoCopyComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    attr_reader :storage
    alias_method :oauth_application, :model

    def initialize(oauth_application:, storage:, **)
      super(oauth_application, **)
      @storage = storage
    end

    def self.wrapper_key = :storage_openproject_oauth_section

    def oauth_application_details_link
      render(
        Primer::Beta::Link.new(
          href: ::Storages::UrlBuilder.url(storage.uri, "settings/admin/openproject"),
          target: "_blank"
        )
      ) { I18n.t("storages.instructions.oauth_application_details_link_text") }
    end

    def submit_button_options
      {
        scheme: :primary,
        tag: :a,
        href: submit_button_path
      }.merge(options.fetch(:submit_button_options, {}))
    end

    private

    def submit_button_path
      options[:submit_button_path] || show_oauth_application_admin_settings_storage_path(storage)
    end
  end
end
