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

require "spec_helper"
require_module_spec_helper

RSpec.describe "Admin work package embeddings", :skip_csrf, type: :rails_request,
                                                            with_flag: { llm_connection: true, semantic_search: true } do
  let(:batch_description) { Llm::IndexWorkPackagesJob::BATCH_DESCRIPTION }

  def create_embed_job(batch, finished_at: nil, error: nil)
    GoodJob::Job.create!(active_job_id: SecureRandom.uuid, job_class: Llm::EmbedWorkPackagesJob.name,
                         queue_name: "default", batch_id: batch.id, error:,
                         performed_at: finished_at && (finished_at - 1.second), finished_at:,
                         serialized_params: { "job_class" => Llm::EmbedWorkPackagesJob.name, "arguments" => [[1, 2]] })
  end

  describe "POST /admin/work_package_embeddings/reindex" do
    context "as admin" do
      before { login_as create(:admin) }

      it "enqueues IndexWorkPackagesJob in a index batch", with_good_job_batches: [Llm::IndexWorkPackagesJob] do
        post reindex_work_package_embeddings_path

        batch = Llm::IndexWorkPackagesJob.latest_batch
        expect(batch.jobs.pluck(:job_class)).to eq([Llm::IndexWorkPackagesJob.name])
      end

      it "does not start another indexing while one is running", with_good_job_batches: [Llm::IndexWorkPackagesJob] do
        GoodJob::BatchRecord.create!(description: batch_description)

        expect { post reindex_work_package_embeddings_path }.not_to change(GoodJob::BatchRecord, :count)
        expect(flash[:warning]).to eq(I18n.t("admin.work_package_embeddings.reindex.already_running"))
      end

      it "redirects to the feature bindings page" do
        post reindex_work_package_embeddings_path

        expect(response).to redirect_to(llm_feature_bindings_path)
      end
    end

    context "as a non-admin" do
      before { login_as create(:user) }

      it "is forbidden" do
        post reindex_work_package_embeddings_path

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with the llm_connection feature flag off", with_flag: { llm_connection: false } do
      before { login_as create(:admin) }

      it "returns 404" do
        post reindex_work_package_embeddings_path

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with the semantic search feature flag off", with_flag: { semantic_search: false } do
      before { login_as create(:admin) }

      it "returns 404" do
        post reindex_work_package_embeddings_path

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
