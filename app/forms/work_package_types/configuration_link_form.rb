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

module WorkPackageTypes
  class ConfigurationLinkForm < ApplicationForm
    # show-when-value-selected wiring keyed on the "mode" radio value. Defined once here
    # so the component's editor wrapper can reuse the exact same triggers.
    class << self
      def cause_data
        { target_name: "mode", "show-when-value-selected-target": "cause" }
      end

      def effect_data(value)
        { target_name: "mode", value:, "show-when-value-selected-target": "effect" }
      end
    end

    form do |source_form|
      source_form.advanced_radio_button_group(name: :mode) do |group|
        group.radio_button(
          value: "independent",
          checked: !linked?,
          label: I18n.t("types.edit.configuration_link.independent.label"),
          caption: I18n.t("types.edit.configuration_link.independent.caption"),
          data: cause_data
        )
        group.radio_button(
          value: "linked",
          checked: linked?,
          label: I18n.t("types.edit.configuration_link.linked.label"),
          caption: I18n.t("types.edit.configuration_link.linked.caption"),
          data: cause_data
        )
      end

      # Persisted Linked: the picker stays visible for both modes — it is the source to
      # link to, and also the type to copy from when switching to Independent (adopt).
      # Persisted Independent: it only appears once "Linked" is selected (see point 1).
      source_form.group(**source_group_options) do |source_group|
        source_group.select_list(
          name: :source_id,
          input_width: :medium,
          label: I18n.t("types.edit.configuration_link.source.label")
        ) do |list|
          source_options.each do |type|
            list.option(value: type.id, label: type.name, selected: type.id == current_source_id)
          end
        end
      end

      switch_confirmation(source_form)
    end

    private

    def cause_data = self.class.cause_data
    def effect_data(value) = self.class.effect_data(value)

    def linked? = @builder.options[:linked]
    def current_source_id = @builder.options[:current_source_id]
    def source_options = @builder.options[:source_options]

    def source_group_options
      return {} if linked?

      { hidden: true, data: effect_data("linked") }
    end

    # The caution message + Save for the mode the type can switch *to*.
    def switch_confirmation(source_form)
      if linked?
        # -> Independent: copy-on-adopt is explained when "Independent" is picked; Save is always available.
        source_form.group(hidden: true, data: effect_data("independent")) do |group|
          group.html_content { warning_flash(I18n.t("types.edit.configuration_link.independent.warning")) }
        end
        source_form.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
      else
        # -> Linked: destructive warning and Save appear together only while "Linked" is picked.
        source_form.group(hidden: true, data: effect_data("linked")) do |group|
          group.html_content { warning_flash(I18n.t("types.edit.configuration_link.linked.warning")) }
          group.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
        end
      end
    end

    def warning_flash(message)
      render(Primer::Beta::Flash.new(scheme: :warning, mb: 3)) { message }
    end
  end
end
