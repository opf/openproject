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

module Storages::Admin
  class SubmitOrCancelForm < ApplicationForm
    form do |buttons|
      buttons.group(layout: :horizontal) do |button_group|
        button_group.submit(**@submit_button_options)
        button_group.button(**@cancel_button_options)
      end
    end

    def initialize(storage:, submit_button_options: {}, cancel_button_options: {})
      super()
      @storage = storage
      @submit_button_options = default_submit_button_options.merge(submit_button_options)
      @cancel_button_options = default_cancel_button_options.merge(cancel_button_options)
    end

    private

    def default_submit_button_options
      {
        name: :submit,
        scheme: :primary,
        label: I18n.t("storages.buttons.save_and_continue"),
        disabled: false
      }
    end

    def default_cancel_button_options
      {
        name: :cancel,
        scheme: :default,
        tag: :a,
        href: OpenProject::StaticRouting::StaticRouter.new.url_helpers.admin_settings_storages_path,
        label: I18n.t("button_cancel")
      }
    end
  end
end
