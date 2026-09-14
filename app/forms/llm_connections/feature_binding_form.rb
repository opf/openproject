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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  # The model select for one registered feature.
  class FeatureBindingForm < ApplicationForm
    # Primer::Forms::Base.new assigns the builder itself and calls this with the
    # remaining keywords, so the builder must not appear in the signature.
    def initialize(options:, inherit_label:, feature_key:, locked: false, embedding: false, dimensions_hint: nil,
                   selected_model_id: nil)
      super()
      @selected_model_id = selected_model_id
      @model_options = options
      @inherit_label = inherit_label
      @feature_key = feature_key
      @locked = locked
      @embedding = embedding
      @dimensions_hint = dimensions_hint
    end

    form do |f|
      # An autocompleter rather than a select, so a model can be found by typing
      # among the hundreds a gateway reports. decorated: true serialises the list
      # into the element, so no endpoint is needed.
      f.autocompleter(
        name: :model_id,
        label: LlmFeatureBinding.human_attribute_name(:model_id),
        disabled: locked,
        autocomplete_options: {
          decorated: true,
          inputValue: selected_model_id,
          placeholder: inherit_label
        },
        data: { test_selector: "llm-feature-binding--model-#{feature_key}" }
      ) do |list|
        list.option(label: inherit_label, value: "", selected: selected_model_id.blank?)

        model_options.each do |option|
          # Listed but not choosable when a required capability is known to be
          # missing: hiding it would leave the reason invisible too.
          list.option(label: option_label(option),
                      value: option.model_id,
                      selected: selected_model_id == option.model_id,
                      disabled: !option.selectable?)
        end
      end

      # Only for an embedding feature, and only while unlocked. A locked binding
      # renders these as text instead: a disabled input submits nothing, so the
      # values would arrive blank and wipe the columns.
      if embedding && !locked
        f.text_field(
          name: :dimensions,
          type: :number,
          min: 1,
          label: LlmFeatureBinding.human_attribute_name(:dimensions),
          caption: dimensions_caption,
          input_width: :small,
          data: { test_selector: "llm-feature-binding--dimensions-#{feature_key}" }
        )

        f.text_field(
          name: :input_prefix,
          label: LlmFeatureBinding.human_attribute_name(:input_prefix),
          caption: I18n.t("admin.llm_feature_bindings.form.input_prefix_caption"),
          input_width: :medium,
          data: { test_selector: "llm-feature-binding--input-prefix-#{feature_key}" }
        )

        f.text_field(
          name: :query_prefix,
          label: LlmFeatureBinding.human_attribute_name(:query_prefix),
          caption: I18n.t("admin.llm_feature_bindings.form.query_prefix_caption"),
          input_width: :medium,
          data: { test_selector: "llm-feature-binding--query-prefix-#{feature_key}" }
        )
      end

      unless locked
        f.submit(
          name: :submit,
          label: I18n.t(:button_save),
          scheme: :secondary,
          data: { test_selector: "llm-feature-binding--submit-#{feature_key}" }
        )
      end
    end

    private

    attr_reader :model_options, :inherit_label, :feature_key, :locked, :embedding, :dimensions_hint,
                :selected_model_id

    # Blank is the right default: the server decides the vector size, and baking
    # in a number it may contradict helps nobody. Where the probe has already
    # seen a vector, its size is offered as information rather than filled in.
    def dimensions_caption
      return I18n.t("admin.llm_feature_bindings.form.dimensions_caption") if dimensions_hint.blank?

      I18n.t("admin.llm_feature_bindings.form.dimensions_caption_probed", dimensions: dimensions_hint)
    end

    def option_label(option)
      case option.state
      when :unsupported
        I18n.t("admin.llm_feature_bindings.option_unsupported",
               model: option.model_id,
               capability: option.reasons.map { |reason| Llm::Capabilities.label(reason) }.join(", "))
      when :unknown
        I18n.t("admin.llm_feature_bindings.option_unknown", model: option.model_id)
      else
        option.model_id
      end
    end
  end
end
