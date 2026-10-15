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

module SemanticIndexes
  class Form < ApplicationForm
    # Primer::Forms::Base.new assigns the builder itself and calls this with the
    # remaining keywords, so the builder must not appear in the signature.
    def initialize(model_options:)
      super()
      @model_options = model_options
    end

    form do |f|
      f.text_field(
        name: :title,
        label: SemanticIndex.human_attribute_name(:title),
        required: true,
        autofocus: true
      )

      f.text_area(
        name: :description,
        label: SemanticIndex.human_attribute_name(:description),
        rows: 3
      )

      f.autocompleter(
        name: :model_id,
        label: SemanticIndex.human_attribute_name(:model_id),
        caption: I18n.t("admin.semantic_indexes.form.model_caption"),
        required: true,
        autocomplete_options: {
          decorated: true,
          inputValue: selected_model_id,
          append_to: "##{LlmConnections::SemanticIndexes::DialogComponent::DIALOG_ID}",
          data: { test_selector: "llm-semantic-index--model" }
        }
      ) do |list|
        model_options.each do |option|
          list.option(label: option_label(option),
                      value: option.model_id,
                      selected: selected_model_id == option.model_id)
        end
      end

      f.text_field(
        name: :context_token_length,
        type: :number,
        min: 1,
        label: SemanticIndex.human_attribute_name(:context_token_length),
        caption: I18n.t("admin.semantic_indexes.form.context_token_length_caption"),
        required: true,
        input_width: :small
      )

      f.text_field(
        name: :embedding_vector_dimensions,
        type: :number,
        min: 1,
        label: SemanticIndex.human_attribute_name(:embedding_vector_dimensions),
        caption: I18n.t("admin.semantic_indexes.form.embedding_vector_dimensions_caption"),
        required: true,
        input_width: :small
      )
    end

    private

    attr_reader :model_options

    def selected_model_id = model.model_id

    def option_label(option)
      return option.model_id if option.qualifies

      I18n.t("admin.semantic_indexes.form.option_unqualified", model: option.model_id)
    end
  end
end
