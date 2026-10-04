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

module Projects
  class SubmitOrCancel < ApplicationForm
    attr_reader :submit_options, :cancel_options

    form do |buttons|
      buttons.group(layout: :horizontal) do |button_group|
        button_group.submit(**submit_options)
        button_group.button(**cancel_options)
      end
    end

    def initialize(submit_options: {}, cancel_options: {})
      super()

      @submit_options = submit_options.with_defaults(default_submit_options)
      @cancel_options = cancel_options.with_defaults(default_cancel_options)
    end

    private

    def default_submit_options
      {
        name: :submit,
        scheme: :primary,
        label: I18n.t("button_create"),
        disabled: false
      }
    end

    def default_cancel_options
      {
        name: :cancel,
        scheme: :default,
        tag: :a,
        href: OpenProject::StaticRouting::StaticRouter.new.url_helpers.projects_path,
        label: I18n.t("button_cancel")
      }
    end
  end
end
