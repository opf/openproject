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

module Webhooks
  class ManualScriptInputForm < ApplicationForm
    form do |f|
      @fields.each { |field| add_field(f, field) }
    end

    def self.model_for(fields, values = {})
      return Struct.new(:_unused).new if fields.empty?

      Struct.new(*fields.map { it.name.to_sym }).new(
        *fields.map { values.key?(it.name) ? values[it.name] : it.default }
      )
    end

    def initialize(fields:, work_package: nil, values: {}, errors: {}, dialog_id: nil)
      super()
      @fields = fields
      @work_package = work_package
      @values = values
      @errors = errors
      @dialog_id = dialog_id
    end

    private

    def add_field(form, field) # rubocop:disable Metrics/AbcSize
      args = {
        name: field.name,
        label: field.title,
        caption: field.description,
        required: field.required,
        validation_message: @errors[field.name]
      }.compact

      case field.kind
      when :text then form.text_field(**args, value: value(field), input_width: :large)
      when :textarea then form.text_area(**args, value: value(field), rows: 4, input_width: :large)
      when :integer, :number
        form.text_field(**args, type: :number, value: value(field), input_width: :small,
                                step: field.kind == :integer ? 1 : "any",
                                min: field.spec["minimum"], max: field.spec["maximum"])
      when :date
        form.single_date_picker(**args, value: value(field), input_width: :small,
                                        leading_visual: { icon: :calendar },
                                        datepicker_options: { inDialog: @dialog_id }.compact)
      when :boolean then form.check_box(**args.except(:required), checked: truthy?(value(field)), value: "1")
      when :radio then radio_group(form, field, args)
      when :select then select(form, field, args)
      when :multi_select then check_boxes(form, field, args)
      when :user then user_autocompleter(form, field, args)
      when :work_package then work_package_autocompleter(form, args)
      when :version then version_autocompleter(form, field, args)
      end
    end

    def radio_group(form, field, args)
      form.radio_button_group(**args) do |group|
        field.options.each do |label, option|
          group.radio_button(value: option, label:, checked: value(field).to_s == option.to_s)
        end
      end
    end

    def select(form, field, args)
      form.select_list(**args, input_width: :medium) do |list|
        list.option(label: "", value: "") unless field.required
        field.options.each do |label, option|
          list.option(label:, value: option, selected: value(field).to_s == option.to_s)
        end
      end
    end

    def check_boxes(form, field, args)
      selected = Array(value(field)).map(&:to_s)
      form.check_box_group(**args.except(:required)) do |group|
        field.options.each do |label, option|
          group.check_box(value: option, label:, checked: selected.include?(option.to_s))
        end
      end
    end

    def user_autocompleter(form, field, args)
      filters = [{ name: "type", operator: "=", values: ["User"] },
                 { name: "status", operator: "=", values: [Principal.statuses[:active].to_s] }]
      filters << { name: "member", operator: "=", values: [@work_package.project_id.to_s] } if @work_package
      form.autocompleter(**args, autocomplete_options: autocomplete_defaults.merge(
        component: "opce-user-autocompleter", resource: "principals", searchKey: "any_name_attribute",
        url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals, filters:, inputValue: value(field)
      ))
    end

    def work_package_autocompleter(form, args)
      filters = @work_package ? [{ name: "project", operator: "=", values: [@work_package.project_id.to_s] }] : []
      form.work_package_autocompleter(**args, autocomplete_options: autocomplete_defaults.merge(filters:))
    end

    def version_autocompleter(form, field, args)
      versions = @work_package ? @work_package.assignable_versions : Version.none
      form.autocompleter(**args, autocomplete_options: autocomplete_defaults.merge(decorated: true)) do |list|
        versions.each do |version|
          list.option(label: version.name, value: version.id, selected: value(field).to_s == version.id.to_s)
        end
      end
    end

    def autocomplete_defaults
      { multiple: false, defaultData: false, focusDirectly: false, append_to: @dialog_id ? "##{@dialog_id}" : "body" }
    end

    def value(field)
      @values.key?(field.name) ? @values[field.name] : field.default
    end

    def truthy?(value)
      [true, "1", "true"].include?(value)
    end
  end
end
