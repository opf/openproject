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

RSpec.describe Llm::EmbedWorkPackagesJob, with_flag: { semantic_search: true } do
  let(:work_package) { create(:work_package) }
  let(:other_work_package) { create(:work_package) }
  let(:semantic_index) { create(:semantic_index, state: "indexing") }

  before { allow(Llm::WorkPackages::EmbedService).to receive(:new).and_call_original }

  it "calls EmbedService with the resolved work packages" do
    service_double = instance_double(Llm::WorkPackages::EmbedService, call: nil)
    allow(Llm::WorkPackages::EmbedService).to receive(:new).and_return(service_double)

    described_class.perform_now(semantic_index.id, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).to have_received(:new) do |index, wps|
      expect(index).to eq(semantic_index)
      expect(wps.map(&:id)).to contain_exactly(work_package.id)
    end
    expect(service_double).to have_received(:call)
  end

  it "does nothing once the Semantic Index is gone" do
    described_class.perform_now(0, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).not_to have_received(:new)
  end

  it "does nothing with the feature flag off", with_flag: { semantic_search: false } do
    described_class.perform_now(semantic_index.id, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).not_to have_received(:new)
  end

  it "does nothing when pgvector is unavailable" do
    allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false)

    described_class.perform_now(semantic_index.id, [work_package.id])

    expect(Llm::WorkPackages::EmbedService).not_to have_received(:new)
  end

  describe "error handling" do
    let(:service) { instance_double(Llm::WorkPackages::EmbedService) }
    let(:work_package_ids) { [work_package.id, other_work_package.id] }

    subject(:perform) { described_class.perform_now(semantic_index.id, work_package_ids) }

    before do
      allow(Llm::WorkPackages::EmbedService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_raise(error)
    end

    shared_examples "splits the job" do
      it "enqueues one job per work package" do
        expect { perform }
          .to have_enqueued_job(described_class).with(semantic_index.id, [work_package.id])
          .and have_enqueued_job(described_class).with(semantic_index.id, [other_work_package.id])
      end

      context "with a single work package" do
        let(:work_package_ids) { [work_package.id] }

        it "gives up without retrying" do
          expect { perform }.not_to have_enqueued_job(described_class)
        end
      end
    end

    shared_examples "retries the job" do
      it "re-enqueues it without splitting" do
        expect { perform }.to have_enqueued_job(described_class).with(semantic_index.id, work_package_ids).exactly(:once)
      end
    end

    shared_examples "fails the job" do
      it "raises without retrying or splitting" do
        expect { perform }.to raise_error(error.class)
        expect(described_class).not_to have_been_enqueued
      end
    end

    [400, 413, 422].each do |status|
      context "when the server refuses the input with a #{status}" do
        let(:error) { Llm::Errors::InvalidInputError.new("invalid input", status:) }

        it_behaves_like "splits the job"
      end
    end

    [400, 429].each do |status|
      context "when the context window is exceeded with a #{status}" do
        let(:error) { Llm::Errors::ContextLengthError.new("too long", status:) }

        it_behaves_like "splits the job"
      end
    end

    [nil, 408, 429, 500, 503].each do |status|
      context "when the server answers with #{status || 'no status'}" do
        let(:error) { Llm::Errors::ApiError.new("down", status:) }

        it_behaves_like "retries the job"
      end
    end

    context "when the request times out" do
      let(:error) { Llm::Errors::TimeoutError.new("timeout") }

      it_behaves_like "retries the job"
    end

    [404, 405, 501].each do |status|
      context "when the server lacks the endpoint with a #{status}" do
        let(:error) { Llm::Errors::ApiError.new("missing", status:) }

        it_behaves_like "fails the job"
      end
    end

    context "when the server rejects the API key" do
      let(:error) { Llm::Errors::AuthenticationError.new("rejected") }

      it_behaves_like "fails the job"
    end

    context "when no connection is available" do
      let(:error) { Llm::Errors::NotReady.new(:no_connection) }

      it_behaves_like "fails the job"
    end

    context "when an unrelated error is raised" do
      let(:error) { ActiveRecord::StatementInvalid.new("boom") }

      it_behaves_like "fails the job"
    end

    context "when the concurrency limit is exceeded" do
      let(:error) { GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError.new }

      it_behaves_like "retries the job"
    end

    context "when a transient error persists" do
      let(:error) { Llm::Errors::ApiError.new("down", status: 503) }
      let(:work_package_ids) { [work_package.id] }

      it "gives up after 10 attempts, keeping the original error as cause" do
        job = described_class.new(semantic_index.id, work_package_ids)
        9.times { job.perform_now }

        expect { job.perform_now }
          .to raise_error(described_class::TransientError) { |raised| expect(raised.cause).to eq(error) }
        expect(service).to have_received(:call).exactly(10).times
      end
    end
  end
end
