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

require "spec_helper"
require_module_spec_helper

RSpec.describe "Admin semantic indexes", :skip_csrf,
               type: :rails_request, with_flag: { llm_connection: true, semantic_search: true },
               with_settings: { llm_features_enabled: true } do
  include_context "with an embedding model offered"

  shared_let(:admin) { create(:admin) }

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:valid_params) do
    { semantic_index: { title: "Nomic small", description: "Trial", model_id: "bge-m3",
                        embedding_vector_dimensions: 768, context_token_length: 2048 } }
  end

  before { login_as admin }

  describe "with the semantic search flag off", with_flag: { llm_connection: true, semantic_search: false } do
    it "does not expose the endpoints" do
      get new_dialog_semantic_indexes_path
      expect(response).to have_http_status(:not_found)

      post semantic_indexes_path, params: valid_params
      expect(response).to have_http_status(:not_found)
      expect(SemanticIndex.count).to eq(0)
    end
  end

  describe "with the semantic search flag on but pgvector unavailable" do
    before { allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false) }

    it "shows the box below the pgvector warning on the feature configuration" do
      create(:semantic_index, title: "Qwen3 baseline")

      get llm_feature_bindings_path

      expect(page).to have_test_selector("llm-feature-bindings--pgvector-unavailable")
      expect(page).to have_test_selector("llm-semantic-index--box", text: "Qwen3 baseline")
    end

    it "creates the semantic index" do
      post semantic_indexes_path, params: valid_params

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(SemanticIndex.sole).to have_attributes(title: "Nomic small", state: "not_indexed")
    end

    it "refuses to start indexing" do
      semantic_index = create(:semantic_index, title: "Qwen3 baseline")

      post start_indexing_semantic_index_path(semantic_index)

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(flash[:error]).to eq(I18n.t("admin.semantic_indexes.indexing.not_ready.pgvector_missing"))
      expect(semantic_index.reload).to be_not_indexed
      expect(GoodJob::Job.where(job_class: Llm::IndexWorkPackagesJob.name)).to be_empty
    end
  end

  describe "as a non-admin" do
    before { login_as create(:user) }

    it "refuses to create an semantic index" do
      post semantic_indexes_path, params: valid_params

      expect(response).to have_http_status(:forbidden)
      expect(SemanticIndex.count).to eq(0)
    end

    it "refuses to start indexing" do
      semantic_index = create(:semantic_index, state: "indexing")

      post start_indexing_semantic_index_path(semantic_index)

      expect(response).to have_http_status(:forbidden)
      expect(semantic_index.reload).to be_indexing
    end

    it "refuses to stop indexing" do
      semantic_index = create(:semantic_index, state: "indexing")

      post stop_indexing_semantic_index_path(semantic_index)

      expect(response).to have_http_status(:forbidden)
      expect(semantic_index.reload).to be_indexing
    end
  end

  describe "GET /admin/llm_feature_bindings" do
    it "lists the semantic indexes below the features" do
      create(:semantic_index, title: "Qwen3 baseline")

      get llm_feature_bindings_path

      expect(response).to have_http_status(:ok)
      expect(page).to have_test_selector("llm-semantic-index--box", text: "Qwen3 baseline")
      expect(page).to have_test_selector("llm-semantic-index--box",
                                         text: I18n.t("admin.semantic_indexes.states.not_indexed"))
      expect(page).to have_test_selector("llm-semantic-index--new-button")
    end

    it "shows an empty state while no semantic index exists" do
      get llm_feature_bindings_path

      expect(page).to have_test_selector("llm-semantic-index--box",
                                         text: I18n.t("admin.semantic_indexes.box.empty_title"))
      expect(page).to have_test_selector("llm-semantic-index--box",
                                         text: I18n.t("admin.semantic_indexes.box.empty_description"))
    end

    it "hides the box without the semantic search flag", with_flag: { llm_connection: true, semantic_search: false } do
      get llm_feature_bindings_path

      expect(page).to have_no_test_selector("llm-semantic-index--box")
    end
  end

  describe "GET new_dialog" do
    it "offers only embedding models" do
      get new_dialog_semantic_indexes_path, headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.semantic_indexes.dialog.new_title"))

      items = Nokogiri::HTML(response.parsed_body).at_css("opce-autocompleter")["data-items"]
      expect(JSON.parse(items).pluck("id")).to contain_exactly("bge-m3")
    end
  end

  describe "POST /admin/semantic_indexes" do
    it "creates the semantic index and returns to the feature configuration" do
      post semantic_indexes_path, params: valid_params

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(SemanticIndex.sole).to have_attributes(title: "Nomic small", model_id: "bge-m3",
                                                    embedding_vector_dimensions: 768,
                                                    context_token_length: 2048, state: "not_indexed")
    end

    it "re-renders the form with errors" do
      post semantic_indexes_path, params: { semantic_index: valid_params[:semantic_index].merge(model_id: "qwen3.6-27b") },
                                  headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("activerecord.errors.models.semantic_index.attributes.model_id.not_offered"))
      expect(SemanticIndex.count).to eq(0)
    end
  end

  describe "existing semantic index" do
    let!(:semantic_index) { create(:semantic_index, title: "Qwen3 baseline") }

    it "renders the edit dialog" do
      get edit_dialog_semantic_index_path(semantic_index), headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include(CGI.escapeHTML(I18n.t("admin.semantic_indexes.dialog.edit_title", title: semantic_index.title)))
    end

    it "locks the parameters in the edit dialog once indexed" do
      semantic_index.update!(state: "failed")

      get edit_dialog_semantic_index_path(semantic_index), headers: turbo_headers

      expect(response.body).to include(CGI.escapeHTML(I18n.t("admin.semantic_indexes.form.locked_once_indexed")))
    end

    it "updates the semantic index" do
      patch semantic_index_path(semantic_index),
            params: { semantic_index: { title: "Qwen3 production", context_token_length: 4096 } }

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(semantic_index.reload).to have_attributes(title: "Qwen3 production", context_token_length: 4096)
    end

    it "renders the deletion dialog" do
      get deletion_dialog_semantic_index_path(semantic_index), headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.semantic_indexes.destroy.heading", title: semantic_index.title))
    end

    it "deletes the semantic index" do
      delete semantic_index_path(semantic_index)

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(SemanticIndex.count).to eq(0)
    end

    context "when indexing", with_good_job_batches: [Llm::IndexWorkPackagesJob] do
      def index_jobs = GoodJob::Job.where(job_class: Llm::IndexWorkPackagesJob.name)

      it "starts indexing" do
        post start_indexing_semantic_index_path(semantic_index)

        expect(response).to redirect_to(llm_feature_bindings_path)
        expect(flash[:notice]).to eq(I18n.t("admin.semantic_indexes.start_indexing.started", title: semantic_index.title))
        expect(semantic_index.reload).to be_indexing
        expect(index_jobs.pluck(:batch_id)).to eq([semantic_index.indexing_batch_id])
      end

      it "re-indexes a ready semantic index" do
        semantic_index.update!(state: "ready")

        post start_indexing_semantic_index_path(semantic_index)

        expect(semantic_index.reload).to be_indexing
        expect(index_jobs.count).to eq(1)
      end

      it "refuses to start indexing twice" do
        semantic_index.update!(state: "indexing")

        post start_indexing_semantic_index_path(semantic_index)

        expect(flash[:error]).to eq(I18n.t("admin.semantic_indexes.start_indexing.not_indexable"))
        expect(index_jobs).to be_empty
      end

      it "shows a stop button while indexing" do
        semantic_index.update!(state: "indexing")

        get llm_feature_bindings_path

        expect(page).to have_test_selector("llm-semantic-index--stop-indexing-#{semantic_index.id}")
        expect(page).to have_no_test_selector("llm-semantic-index--start-indexing-#{semantic_index.id}")
      end

      it "stops indexing and discards the queued jobs" do
        post start_indexing_semantic_index_path(semantic_index)
        batch_id = semantic_index.reload.indexing_batch_id
        expect(GoodJob::Job.where(batch_id:)).not_to be_empty

        post stop_indexing_semantic_index_path(semantic_index)

        expect(response).to redirect_to(llm_feature_bindings_path)
        expect(flash[:notice]).to eq(I18n.t("admin.semantic_indexes.stop_indexing.stopped", title: semantic_index.title))
        expect(semantic_index.reload).to be_not_indexed
        expect(GoodJob::Job.where(batch_id:).reload.map(&:status)).to all(eq(:discarded))
      end

      it "refuses to stop when not indexing" do
        post stop_indexing_semantic_index_path(semantic_index)

        expect(response).to redirect_to(llm_feature_bindings_path)
        expect(flash[:error]).to eq(I18n.t("admin.semantic_indexes.stop_indexing.not_indexing"))
        expect(semantic_index.reload).to be_not_indexed
      end
    end
  end

  describe "activation" do
    let!(:current) { create(:semantic_index, title: "Qwen3 baseline", state: "ready") }
    let!(:candidate) { create(:semantic_index, title: "Nomic small", state: "ready") }

    before { connection.feature_bindings.create!(feature_key: "semantic_search", semantic_index: current) }

    it "groups the active semantic index above the others" do
      get llm_feature_bindings_path

      rows = page.all("[data-test-selector^='llm-semantic-index--row-']")
      expect(rows.pluck("data-test-selector"))
        .to eq(["llm-semantic-index--row-#{current.id}", "llm-semantic-index--row-#{candidate.id}"])

      active_row = page.find("[data-test-selector='llm-semantic-index--row-#{current.id}']")
      expect(active_row).to have_test_selector("llm-semantic-index--active-label",
                                               text: I18n.t("admin.semantic_indexes.active"))
      expect(active_row).to have_text("Qwen3 baseline")
      expect(active_row).to have_no_test_selector("llm-semantic-index--activate-#{current.id}")

      candidate_row = page.find("[data-test-selector='llm-semantic-index--row-#{candidate.id}']")
      expect(candidate_row).to have_no_test_selector("llm-semantic-index--active-label")
      expect(candidate_row).to have_test_selector("llm-semantic-index--activate-#{candidate.id}")
    end

    it "names both Semantic Indexes in the confirmation dialog" do
      get activation_dialog_semantic_index_path(candidate), headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.semantic_indexes.activate.body_switch_html",
                                              current: current.title, title: candidate.title))
    end

    it "activates a ready semantic index" do
      post activate_semantic_index_path(candidate)

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(flash[:notice]).to eq(I18n.t("admin.semantic_indexes.activate.success", title: candidate.title))
      expect(SemanticIndex.semantic_search_binding.semantic_index).to eq(candidate)
    end

    it "refuses to delete the active semantic index" do
      delete semantic_index_path(current)

      expect(flash[:error]).to include(I18n.t("activerecord.errors.models.semantic_index.attributes.base.active"))
      expect(SemanticIndex.exists?(current.id)).to be(true)
    end
  end

  describe "GET status" do
    it "reports the progress of a semantic index that is indexing and keeps polling" do
      batch = GoodJob::Batch.new.tap(&:save)
      create(:semantic_index, state: "indexing", indexing_batch_id: batch.id)
      [Time.current, nil, nil, nil].each do |finished_at|
        GoodJob::Job.create!(id: SecureRandom.uuid, active_job_id: SecureRandom.uuid, batch_id: batch.id,
                             job_class: Llm::EmbedWorkPackagesJob.name, queue_name: "default",
                             serialized_params: {}, finished_at:)
      end

      get status_semantic_indexes_path, headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("turbo-stream",
                                       I18n.t("admin.semantic_indexes.indexing.progress", percentage: 25),
                                       "poll-for-changes")
    end

    it "replaces the box once indexing has finished" do
      create(:semantic_index, state: "failed", error_message: "Some Error")

      get status_semantic_indexes_path, headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("turbo-stream",
                                       I18n.t("admin.semantic_indexes.states.failed"),
                                       "Some Error")
    end
  end
end
