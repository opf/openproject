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

RSpec.describe LlmConnections::SemanticIndexes::DialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  include_context "with an embedding model offered"

  subject(:rendered_component) do
    with_request_url "/admin/llm_feature_bindings" do
      render_inline(described_class.new(semantic_index, connection:))
    end
  end

  context "for a new semantic index" do
    let(:semantic_index) { SemanticIndex.new }

    it "offers creating the index" do
      rendered_component

      expect(page).to have_css("h1", text: "New Semantic Index")
      expect(page).to have_css(
        "button[form='#{LlmConnections::SemanticIndexes::FormComponent::FORM_ID}'][type='submit']",
        text: "Create"
      )
      expect(page).to have_css("button[data-close-dialog-id='llm-semantic-index-dialog']", text: "Cancel")
    end
  end

  context "for a persisted semantic index" do
    let(:semantic_index) { create(:semantic_index, title: "Qwen3 baseline") }

    it "offers saving the index under its current title" do
      rendered_component

      expect(page).to have_css("h1", text: 'Edit "Qwen3 baseline"')
      expect(page).to have_css(
        "button[form='#{LlmConnections::SemanticIndexes::FormComponent::FORM_ID}'][type='submit']",
        text: "Save"
      )
    end
  end
end
