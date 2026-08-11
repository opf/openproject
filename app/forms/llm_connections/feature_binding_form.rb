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
    def initialize(options:, inherit_label:, feature_key:, locked: false)
      super()
      @model_options = options
      @inherit_label = inherit_label
      @feature_key = feature_key
      @locked = locked
    end

    form do |f|
      f.select_list(
        name: :model_id,
        label: LlmFeatureBinding.human_attribute_name(:model_id),
        include_blank: false,
        input_width: :large,
        disabled: locked,
        data: { test_selector: "llm-feature-binding--model-#{feature_key}" }
      ) do |select|
        select.option(value: "", label: inherit_label)

        model_options.each do |option|
          # Listed but not choosable when a required capability is known to be
          # missing: hiding it would leave the reason invisible too.
          select.option(value: option.model_id, label: option_label(option), disabled: !option.selectable?)
        end
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

    attr_reader :model_options, :inherit_label, :feature_key, :locked

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
