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

module Workflows
  class Form < ApplicationForm
    form do |workflow_form|
      workflow_form.text_field(name: :name,
                               label: I18n.t("workflows.form.name.label"),
                               caption: I18n.t("workflows.form.name.caption"),
                               required: true,
                               autofocus: true)

      workflow_form.text_field(name: :description,
                               label: I18n.t("workflows.form.description.label"),
                               caption: I18n.t("workflows.form.description.caption"))

      next if model.persisted? || copy_sources.empty?

      workflow_form.autocompleter(
        name: :copy_from_id,
        label: I18n.t("workflows.form.copy_from.label"),
        caption: I18n.t("workflows.form.copy_from.caption"),
        autocomplete_options: {
          placeholder: I18n.t("workflows.form.copy_from.placeholder"),
          decorated: true,
          multiple: false,
          focusDirectly: false,
          append_to: "##{FormComponent::DIALOG_ID}",
          data: { test_selector: "workflow-copy-from" }
        }
      ) do |list|
        copy_sources.each { |source| list.option(value: source.id, label: source.name) }
      end
    end

    private

    def copy_sources
      @copy_sources ||= Workflow.available_in(model.project).in_display_order.to_a
    end
  end
end
