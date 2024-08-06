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
  class GeneralInfoFormComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    alias_method :storage, :model

    options form_method: :post,
            submit_button_disabled: false

    def self.wrapper_key = :storage_general_info_section

    def form_url
      options[:form_url] || default_form_url
    end

    def submit_button_options
      { disabled: submit_button_disabled }
    end

    def cancel_button_options
      { href: cancel_button_path,
        data: { turbo_stream: true } }.tap do |options_hash|
        if storage.new_record?
          options_hash[:data][:turbo_stream] = false
          options_hash[:target] = "_top" # Break out of Turbo Frame, follow full page redirect
        end
      end
    end

    private

    def default_form_url
      case form_method
      when :get, :post
        admin_settings_storages_path
      when :patch, :put
        admin_settings_storage_path(storage)
      end
    end

    def cancel_button_path
      options.fetch(:cancel_button_path) do
        if storage.persisted?
          edit_admin_settings_storage_path(storage)
        else
          admin_settings_storages_path
        end
      end
    end

    def provider_configuration_instructions
      caption_for_provider_type(storage.short_provider_type)
    end

    def caption_for_provider_type(provider_type)
      I18n.t(
        "storages.instructions.#{provider_type}.provider_configuration",
        application_link_text: application_link_text_for(
          ::OpenProject::Static::Links[:storage_docs][:"#{provider_type}_oauth_application"][:href],
          I18n.t("storages.instructions.#{provider_type}.application_link_text")
        )
      ).html_safe
    end

    def application_link_text_for(href, link_text)
      render(Primer::Beta::Link.new(href:, target: "_blank")) { link_text }
    end
  end
end
