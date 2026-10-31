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

require "rails_helper"
require_module_spec_helper

RSpec.describe LlmConnections::SemanticIndexes::FormComponent, type: :component do
  include Rails.application.routes.url_helpers

  include_context "with an embedding model offered"

  subject(:rendered_component) do
    with_request_url "/admin/llm_feature_bindings" do
      render_inline(described_class.new(semantic_index, connection:))
    end
  end

  context "for a new semantic index" do
    let(:semantic_index) { SemanticIndex.new }

    it "posts to the semantic indexes collection route" do
      rendered_component

      expect(page).to have_css("form[action='#{semantic_indexes_path}'][method='post']")
    end

    it "offers the connection's embedding models" do
      rendered_component

      autocompleter = page.find("[data-test-selector='llm-semantic-index--model']")
      expect(autocompleter[:"data-input-name"]).to include("semantic_index[model_id]")
      expect(autocompleter[:"data-items"]).to include("bge-m3")
    end
  end

  context "for a persisted semantic index" do
    let(:semantic_index) { create(:semantic_index, title: "Qwen3 baseline", model_id: "bge-m3") }

    it "patches the semantic index's own route" do
      rendered_component

      expect(page).to have_css("form[action='#{semantic_index_path(semantic_index)}']")
      expect(page).to have_css("input[name='_method'][value='patch']", visible: :all)
    end

    it "preselects the index's model" do
      rendered_component

      autocompleter = page.find("[data-test-selector='llm-semantic-index--model']")
      expect(autocompleter[:"data-input-value"]).to include("bge-m3")
    end
  end

  context "when the parameters are locked" do
    let(:semantic_index) { create(:semantic_index, state: :ready) }

    it "warns that the parameters cannot be changed" do
      rendered_component

      expect(page).to have_text(I18n.t("admin.semantic_indexes.form.locked_once_indexed"))
    end

    it "renders the parameter fields disabled" do
      rendered_component

      expect(page).to have_field(SemanticIndex.human_attribute_name(:model_id), disabled: true)
      expect(page).to have_field(SemanticIndex.human_attribute_name(:context_token_length), disabled: true)
      expect(page).to have_field(SemanticIndex.human_attribute_name(:embedding_vector_dimensions), disabled: true)
      expect(page).to have_no_css("[data-test-selector='llm-semantic-index--model']")
    end
  end

  context "with a validation error on the title" do
    let(:semantic_index) { build(:semantic_index, title: "Qwen3 baseline") }

    before { semantic_index.errors.add(:title, :blank) }

    it "still posts to the semantic indexes collection route" do
      rendered_component

      expect(page).to have_css("form[action='#{semantic_indexes_path}'][method='post']")
    end

    it "renders the error message next to the field" do
      rendered_component

      expect(page).to have_text(semantic_index.errors.full_messages_for(:title).first)
    end
  end
end
