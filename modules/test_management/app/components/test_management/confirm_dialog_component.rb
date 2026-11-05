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

module TestManagement
  class ConfirmDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    attr_reader :id, :test_selector, :i18n_scope, :form_arguments, :label

    def initialize(id:, test_selector:, i18n_scope:, form_arguments:, label:)
      super
      @id = id
      @test_selector = test_selector
      @i18n_scope = i18n_scope
      @form_arguments = form_arguments
      @label = label
    end

    private

    def title = I18n.t("#{i18n_scope}.title")
    def heading = I18n.t("#{i18n_scope}.heading")
    def description = I18n.t("#{i18n_scope}.description", name: label)
    def confirmation_checkbox_text = I18n.t("#{i18n_scope}.confirm")
    def confirm_button_text = I18n.t("#{i18n_scope}.confirm_button")
  end
end
