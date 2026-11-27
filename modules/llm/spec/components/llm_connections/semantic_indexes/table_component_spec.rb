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

RSpec.describe LlmConnections::SemanticIndexes::TableComponent, type: :component do
  let(:semantic_index) { create(:semantic_index, :ready) }

  subject(:rendered_component) do
    with_request_url "/admin/llm_feature_bindings" do
      render_inline(described_class.new(rows: [semantic_index], active_semantic_index_id: nil))
    end
  end

  context "when the semantic index failed" do
    let(:semantic_index) { create(:semantic_index, error_message: "No active LLM connection is configured.") }

    it "shows the error" do
      rendered_component

      expect(page).to have_text("No active LLM connection is configured.")
    end
  end

  it "shows the error of the last run also while the semantic index is searchable" do
    semantic_index.update!(error_message: "Indexing failed: rejected")

    rendered_component

    expect(page).to have_text("Indexing failed: rejected")
  end

  it "shows the work packages that failed to index in the progress bar" do
    create(:work_package_embedding, semantic_index:, embedding: nil, failed_at: Time.current)

    rendered_component

    expect(page).to have_css(".Progress-item.color-bg-danger-emphasis[style*='width: 50%']")
    expect(page).to have_text(I18n.t("admin.semantic_indexes.indexing.progress", percentage: 100))
    expect(page).to have_text(I18n.t("admin.semantic_indexes.indexing.failed_work_packages", count: 1))
  end
end
