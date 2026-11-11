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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Repositories::Admin
  class SubmitOrCancelForm < ApplicationForm
    form do |buttons|
      buttons.group(layout: :horizontal) do |button_group|
        button_group.submit(name: :submit, scheme: :primary, label: submit_label)
        button_group.button(
          name: :cancel,
          scheme: :default,
          tag: :a,
          href: cancel_path,
          label: I18n.t(:button_cancel),
          data: { turbo_frame: "_top" }
        )
      end
    end

    def initialize(provider:, in_wizard:)
      super()
      @provider = provider
      @in_wizard = in_wizard
    end

    private

    def submit_label
      if @in_wizard || @provider.new_record?
        I18n.t("repositories.admin.buttons.save_and_continue")
      else
        I18n.t(:button_save)
      end
    end

    def cancel_path
      if @provider.persisted?
        url_helpers.edit_admin_settings_repository_provider_path(@provider)
      else
        url_helpers.admin_settings_repository_providers_path
      end
    end
  end
end
