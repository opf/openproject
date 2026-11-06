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

module Budgets
  class CreateOrContinue < ApplicationForm
    extend Dry::Initializer

    option :create_options, default: -> { {} }
    option :continue_options, default: -> { {} }

    form do |buttons|
      buttons.group(layout: :horizontal) do |button_group|
        button_group.submit(**create_options)
        button_group.submit(**continue_options)
      end
    end

    def initialize(...)
      super

      @create_options.with_defaults!(default_create_options)
      @continue_options.with_defaults!(default_continue_options)
    end

    private

    def default_create_options
      {
        name: :create,
        scheme: :secondary,
        label: I18n.t("button_create"),
        data: { test_selector: "budgets-create-button" }
      }
    end

    def default_continue_options
      {
        name: :continue,
        scheme: :primary,
        label: I18n.t("button_create_and_continue"),
        data: { test_selector: "budgets-continue-button" }
      }
    end
  end
end
