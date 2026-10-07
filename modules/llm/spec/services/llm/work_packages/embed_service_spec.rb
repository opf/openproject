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

RSpec.describe Llm::WorkPackages::EmbedService do
  let(:work_package) { create(:work_package, subject: "Fix bug") }
  let(:connection) { create(:llm_connection, :with_models) }
  let(:binding) do
    create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search",
                                 model_id: "bge-m3", dimensions: 3)
  end
  let(:session_double) { instance_double(Llm::Session) }
  let(:embedding_double) { instance_double(RubyLLM::Embedding, vectors: [[0.1, 0.2, 0.3]]) }

  subject(:service) { described_class.new([work_package]) }

  context "when no binding exists" do
    it "raises" do
      expect { service.call }.to raise_error(RuntimeError, "no binding")
    end
  end

  context "when a binding exists but has no resolved model" do
    before do
      create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search",
                                   model_id: nil, dimensions: nil)
    end

    it "raises" do
      expect { service.call }.to raise_error(RuntimeError, "no binding")
    end
  end

  context "when a ready binding exists" do
    before do
      binding
      allow(Llm::Session).to receive(:for).with(connection).and_return(session_double)
      allow(session_double).to receive(:embed).and_return(embedding_double)
    end

    it "stores the embedding" do
      service.call

      record = WorkPackageEmbedding.find_by!(work_package:)
      expect(record.model_id).to eq("bge-m3")
      expect(record.dimensions).to eq(3)
    end

    it "returns :ok" do
      expect(service.call).to eq(:ok)
    end

    it "locks the binding on first write" do
      expect { service.call }.to change { binding.reload.locked? }.from(false).to(true)
    end

    it "does not modify locked_at on a subsequent write" do
      binding.update!(locked_at: 1.hour.ago)
      locked_at_before = binding.locked_at

      service.call

      expect(binding.reload.locked_at).to be_within(1.second).of(locked_at_before)
    end
  end
end
