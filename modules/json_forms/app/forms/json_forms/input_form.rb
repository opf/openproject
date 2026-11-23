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

module JsonForms
  # Renders a form for the data described by a JSON Schema, laid out by an optional JSON Forms UI schema.
  #
  # Rules and Add/Remove buttons re-render the form on the server: render it inside a form built from
  # `form_arguments` and answer the refresh URL with a morphing update (see SubmittedInput).
  # The context (project:, work_package:, overlay_id:) is passed to format renderers, see Formats.
  class InputForm < ApplicationForm
    # Every value is passed explicitly, so the form builder must not look anything up on a model.
    class ValuelessModel
      def method_missing(*) = nil
      def respond_to_missing?(*) = true
    end

    # Primer asks each input of a fieldset whether it is hidden, which a nested fieldset cannot answer by itself.
    class NestedFieldset < Primer::Forms::Dsl::FieldsetGroupInput
      def hidden? = false
    end

    # Prefixes of parameters holding form state besides the data: the names typed into "new property" fields
    # (followed by the object's path) and the selected tab of categorizations (followed by its id).
    NEW_PROPERTY_PARAM = "_new_property:"
    CATEGORY_PARAM = "_category:"
    STATE_PARAMS = [NEW_PROPERTY_PARAM, CATEGORY_PARAM].freeze

    form do |f|
      # Pressing Enter in a field submits the form through its first submit button, which would otherwise be
      # an Add/Remove button of the form. This invisible one comes first and submits normally instead.
      f.html_content { helpers.tag.button(type: :submit, hidden: true, tabindex: -1, "aria-hidden": true) }
      render_element(f, @ui_schema, @schema, [], @data, enabled: true)
      render_additional_properties(f, @schema, [], @data, enabled: true) unless @ui_schema_given
    end

    def self.form_arguments(url:, refresh_url: nil, scope: :input)
      data = { turbo_stream: true }
      if refresh_url
        data.merge!(controller: "refresh-on-form-changes", refresh_on_form_changes_target: "form",
                    refresh_on_form_changes_turbo_stream_url_value: refresh_url)
      end
      { model: ValuelessModel.new, scope:, url:, method: :post, data: }
    end

    def initialize(schema:, ui_schema: nil, data: {}, errors: {}, context: {}, refresh_url: nil, scope: :input,
                   state: {})
      super()
      @schema = schema
      @ui_schema_given = ui_schema.present?
      @ui_schema = ui_schema.presence || UiSchema.generate(schema)
      @state = state
      @data = data
      @errors = errors
      @context = context
      @refresh_url = refresh_url
      @scope = scope.to_s
      @rule_scopes = UiSchema.rule_scopes(@ui_schema)
      @fieldset_count = 0
      @categorization_count = 0
    end

    private

    # Scopes of controls are resolved against context_schema/context_data: the root object, or an array item.
    def render_element(container, element, context_schema, path, context_data, enabled:) # rubocop:disable Metrics/AbcSize
      return unless UiSchema.visible?(element, context_data)

      enabled &&= UiSchema.enabled?(element, context_data)
      render_children = ->(target) do
        Array(element["elements"]).each { render_element(target, it, context_schema, path, context_data, enabled:) }
      end

      case element["type"]
      when "VerticalLayout" then render_children.call(container)
      when "HorizontalLayout" then container.group(layout: :horizontal, &render_children)
      when "Group" then fieldset(container, element["label"], &render_children)
      when "Label" then container.html_content { render(Primer::Beta::Text.new(tag: :p, color: :muted)) { element["text"] } }
      when "Categorization" then render_categorization(container, element, context_schema, path, context_data, enabled:)
      when "Control" then render_control(container, element, context_schema, path, context_data, enabled:)
      end
    end

    # JSON Forms' tabs. All categories stay in the page, so switching happens in the browser and every value is
    # submitted; the selected tab is sent along to keep it across refreshes. After failed validation, a tab with
    # errors is selected unless the selected one has errors itself.
    def render_categorization(container, element, context_schema, path, context_data, enabled:) # rubocop:disable Metrics/AbcSize
      categories = Array(element["elements"]).select { it["type"] == "Category" && UiSchema.visible?(it, context_data) }
      return if categories.empty?

      @categorization_count += 1
      id = "#{@scope}-categorization-#{@categorization_count}"
      with_errors = categories.map { category_errors?(it, path) }
      selected = selected_category(id, with_errors)

      container.group(id:, data: { controller: "json-forms--categorization" }) do |group|
        group.html_content { category_tabs(id, categories, selected, with_errors) }
        categories.each_with_index do |category, index|
          panel_arguments = { id: "#{id}-panel-#{index}", role: :tabpanel, hidden: index != selected,
                              aria: { labelledby: "#{id}-tab-#{index}" },
                              data: { json_forms__categorization_target: "panel" } }
          category_enabled = enabled && UiSchema.enabled?(category, context_data)
          group.group(**panel_arguments) do |panel|
            Array(category["elements"]).each do |child|
              render_element(panel, child, context_schema, path, context_data, enabled: category_enabled)
            end
          end
        end
      end
    end

    def category_tabs(id, categories, selected, with_errors) # rubocop:disable Metrics/AbcSize
      tabs = categories.each_with_index.map do |category, index|
        category_tab(id, category["label"].to_s, index, selected:, with_error: with_errors[index])
      end
      list = helpers.tag.div(class: "UnderlineNav-body", role: :tablist) { helpers.safe_join(tabs) }
      helpers.tag.nav(class: "UnderlineNav mb-3") { helpers.safe_join([selected_category_input(id, selected), list]) }
    end

    def selected_category_input(id, selected)
      helpers.hidden_field_tag("#{CATEGORY_PARAM}#{id}", selected, id: nil, data: { json_forms__categorization_target: "input" })
    end

    def category_tab(id, label, index, selected:, with_error:)
      helpers.tag.button(
        type: :button, id: "#{id}-tab-#{index}", class: "UnderlineNav-item", role: :tab,
        aria: { selected: (index == selected).to_s, controls: "#{id}-panel-#{index}" },
        data: { action: "json-forms--categorization#select", index:, json_forms__categorization_target: "tab",
                test_selector: "json-form-category" }
      ) do
        helpers.safe_join([label, (category_error_icon if with_error)].compact)
      end
    end

    def category_error_icon
      render(Primer::Beta::Octicon.new(icon: :alert, color: :danger, ml: 1,
                                       aria: { label: I18n.t("json_forms.form.category_has_errors") }))
    end

    def selected_category(id, with_errors)
      selected = Integer(@state["#{CATEGORY_PARAM}#{id}"].to_s, exception: false) || 0
      selected = 0 unless selected.between?(0, with_errors.size - 1)
      with_errors[selected] || with_errors.none? ? selected : with_errors.index(true)
    end

    def category_errors?(category, path)
      prefixes = control_paths(category, path).map { it.join(".") }
      @errors.keys.any? { |key| prefixes.any? { |prefix| key == prefix || key.start_with?("#{prefix}.") } }
    end

    def control_paths(element, path)
      return [[*path, *UiSchema.scope_keys(element["scope"])]] if element["type"] == "Control"

      Array(element["elements"]).flat_map { control_paths(it, path) }
    end

    def render_control(container, element, context_schema, path, context_data, enabled:) # rubocop:disable Metrics/AbcSize
      keys = UiSchema.scope_keys(element["scope"])
      schema = UiSchema.schema_at(context_schema, keys)
      return unless schema.is_a?(Hash)

      field_path = path + keys
      value = FormData.dig(context_data, keys)
      args = input_arguments(element, schema, field_path, required: required?(context_schema, keys), enabled:)

      case schema["type"]
      when "object" then render_object(container, element, schema, field_path, value || {}, args)
      when "array"
        if Options.for(schema["items"])
          check_box_group(container, Options.for(schema["items"]), Array(value), args)
        else
          render_array(container, element, schema, field_path, value, args)
        end
      else render_input(container, schema, value, args)
      end
    end

    def input_arguments(element, schema, field_path, required:, enabled:)
      {
        name: field_name(field_path),
        id: field_id(field_path),
        scope_name_to_model: false,
        scope_id_to_model: false,
        label: label_for(element, schema, field_path),
        visually_hide_label: element["label"] == false || nil,
        required:,
        caption: schema["description"],
        validation_message: @errors[field_path.join(".")],
        disabled: !enabled || nil,
        data: refresh_trigger(field_path)
      }.compact
    end

    def render_input(container, schema, value, args)
      options = Options.for(schema)
      if schema["type"] == "boolean"
        container.check_box(**args.except(:required), checked: value == true, value: "1")
      elsif options
        options.size <= 4 ? radio_group(container, options, value, args) : select(container, options, value, args)
      elsif %w[integer number].include?(schema["type"])
        number_field(container, schema, value, args)
      else
        render_string(container, schema, value, args)
      end
      submit_disabled_value(container, value, args)
    end

    def render_string(container, schema, value, args)
      if (renderer = Formats.for(schema["format"]))
        renderer.call(container, value:, arguments: args, context: @context)
      elsif schema["format"] == "textarea"
        container.text_area(**args, value:, rows: 3)
      else
        container.text_field(**args, type: text_type(schema), value:)
      end
    end

    def number_field(container, schema, value, args)
      container.text_field(**args, type: :number, value:,
                                   step: schema["type"] == "integer" ? 1 : "any",
                                   min: schema["minimum"], max: schema["maximum"])
    end

    def render_object(container, element, schema, field_path, value, args)
      detail = element.dig("options", "detail") || UiSchema.generate(schema)
      fieldset(container, args[:label], bordered: true) do |group|
        render_element(group, detail, schema, field_path, value, enabled: !args[:disabled])
        render_additional_properties(group, schema, field_path, value, enabled: !args[:disabled])
      end
    end

    # Properties not listed in "properties", each with a Remove button, and a field to add another one.
    def render_additional_properties(container, schema, path, value, enabled:)
      value_schema = UiSchema.additional_properties_schema(schema)
      return unless value_schema

      extra_keys = (value.is_a?(Hash) ? value.keys : []) - schema.fetch("properties", {}).keys
      extra_keys.each do |key|
        container.group(layout: :horizontal, data: { test_selector: "json-form-additional-property" }) do |row|
          render_control(row, { "type" => "Control", "scope" => "#", "label" => key }, value_schema, [*path, key],
                         value[key], enabled:)
          row.html_content { operation_button(:remove, [*path, key], disabled: !enabled) }
        end
      end
      render_new_property(container, path, enabled:)
    end

    def render_new_property(container, path, enabled:)
      name = "#{NEW_PROPERTY_PARAM}#{path.join('.')}"
      container.text_field(name:, id: field_id([*path, "new_property"]), scope_name_to_model: false, scope_id_to_model: false,
                           label: I18n.t("json_forms.form.property_name"), value: @state[name],
                           validation_message: @errors[name], disabled: !enabled || nil)
      container.html_content { operation_button(:add_property, path, disabled: !enabled) }
    end

    def render_array(container, element, schema, field_path, value, args) # rubocop:disable Metrics/AbcSize
      item_schema = schema["items"].is_a?(Hash) ? schema["items"] : {}
      detail = element.dig("options", "detail") || UiSchema.generate(item_schema)
      items = Array(value)
      fieldset(container, args[:label], bordered: true, description: args[:validation_message]) do |group|
        items.each_with_index do |item, index|
          render_array_item(group, detail, item_schema, [*field_path, index.to_s], item, enabled: !args[:disabled])
        end
        group.html_content { no_items_text } if items.empty?
        group.html_content { operation_button(:add, field_path, disabled: args[:disabled] || full?(schema, items)) }
      end
    end

    def render_array_item(container, detail, item_schema, item_path, item, enabled:)
      container.group(layout: :horizontal, data: { test_selector: "json-form-array-item" }) do |row|
        render_element(row, detail, item_schema, item_path, item, enabled:)
        row.html_content { operation_button(:remove, item_path, disabled: !enabled) }
      end
    end

    def fieldset(container, title, bordered: false, description: nil, &)
      @fieldset_count += 1
      input = NestedFieldset.new(
        builder: container.builder, form: container.form, title: title.presence || "", description:,
        heading_arguments: { id: "#{@scope}-section-#{@fieldset_count}" },
        # Nested sections fill the row they share with a Remove button, like plain inputs do.
        **(bordered ? { mb: 2, p: 3, border: true, border_radius: 2, style: "flex: 1 1 auto; min-width: 0" } : {}),
        &
      )
      container.send(:add_input, input)
    end

    def operation_button(operation, path, disabled:)
      label = I18n.t("json_forms.form.#{operation}")
      button = Primer::Beta::Button.new(
        type: :submit, name: "_operation", value: "#{operation}:#{path.join('.')}", size: :small,
        scheme: operation == :remove ? :invisible : :default, disabled: disabled || @refresh_url.nil?,
        formaction: @refresh_url, aria: { label: }, test_selector: "json-form-#{operation.to_s.dasherize}"
      )
      helpers.content_tag(:div) do
        render(button) do |component|
          component.with_leading_visual_icon(icon: operation == :remove ? :trash : :plus)
          label unless operation == :remove
        end
      end
    end

    def no_items_text
      render(Primer::Beta::Text.new(tag: :p, color: :muted)) { I18n.t("json_forms.form.no_items") }
    end

    def radio_group(container, options, value, args)
      container.radio_button_group(**args.except(:id)) do |group|
        options.each_with_index do |(label, option), index|
          group.radio_button(value: option, label:, checked: value.to_s == option.to_s, id: "#{args[:id]}_#{index}",
                             scope_name_to_model: false, scope_id_to_model: false)
        end
      end
    end

    def select(container, options, value, args)
      container.select_list(**args, include_blank: I18n.t("json_forms.form.select_prompt")) do |list|
        options.each { |label, option| list.option(label:, value: option, selected: value.to_s == option.to_s) }
      end
    end

    def check_box_group(container, options, values, args)
      selected = values.map(&:to_s)
      container.check_box_group(**args.except(:required, :id, :name), name: "#{args[:name]}[]") do |group|
        options.each_with_index do |(label, option), index|
          group.check_box(value: option, label:, checked: selected.include?(option.to_s),
                          id: "#{args[:id]}_#{index}", scope_name_to_model: false, scope_id_to_model: false)
        end
      end
      values.each { container.hidden(name: "#{args[:name]}[]", value: it, scope_name_to_model: false) } if args[:disabled]
    end

    # Disabled inputs are not submitted; keep their values like JSON Forms does.
    def submit_disabled_value(container, value, args)
      return unless args[:disabled] && !value.nil?

      container.hidden(name: args[:name], value: value == true ? "1" : value, scope_name_to_model: false)
    end

    # Inputs that a rule depends on re-render the form when they change.
    def refresh_trigger(field_path)
      return unless @refresh_url && @rule_scopes.any? { |keys| keys.any? && field_path.last(keys.size) == keys }

      { action: "change->refresh-on-form-changes#triggerTurboStream" }
    end

    def required?(context_schema, keys)
      return false if keys.empty?

      parent = UiSchema.schema_at(context_schema, keys[0..-2])
      Array(parent&.fetch("required", nil)).include?(keys.last)
    end

    def full?(schema, value)
      schema["maxItems"].is_a?(Integer) && Array(value).size >= schema["maxItems"]
    end

    def label_for(element, schema, field_path)
      label = element["label"]
      key = field_path.last.to_s
      (label.is_a?(String) && label.presence) || schema["title"].presence ||
        (key.match?(/\A\d+\z/) ? (key.to_i + 1).to_s : key.humanize)
    end

    def text_type(schema)
      { "email" => :email, "uri" => :url }.fetch(schema["format"], :text)
    end

    def field_name(path) = "#{@scope}#{path.map { "[#{it}]" }.join}"

    def field_id(path) = [@scope, *path].join("_")
  end
end
