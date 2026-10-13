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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Llm::WorkPackages::SemanticSearch do
  let(:connection) { create(:llm_connection, :with_models) }
  let(:session_double) { instance_double(Llm::Session) }
  let(:embedding_double) { instance_double(RubyLLM::Embedding, vectors: [0.1, 0.2, 0.3]) }

  def create_binding(locked_at: Time.current)
    create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search",
                                 model_id: "bge-m3", dimensions: 3, locked_at:)
  end

  describe ".available?" do
    it "is false without a binding" do
      expect(described_class).not_to be_available
    end

    it "is false while the binding is not locked" do
      create_binding(locked_at: nil)

      expect(described_class).not_to be_available
    end

    it "is true once the binding is locked" do
      create_binding

      expect(described_class).to be_available
    end
  end

  describe ".query_vector" do
    before do
      allow(Llm::Session).to receive(:for).with(connection).and_return(session_double)
      allow(session_double).to receive(:embed).and_return(embedding_double)
    end

    it "returns nothing without a locked binding" do
      create_binding(locked_at: nil)

      expect(described_class.query_vector("some query")).to be_nil
    end

    context "with a locked binding" do
      before { create_binding }

      it "embeds the query as a vector literal" do
        expect(described_class.query_vector("some query")).to eq("[0.1,0.2,0.3]")
        expect(session_double).to have_received(:embed).with("some query", model: "bge-m3", dimensions: 3)
      end

      it "embeds the same query only once per request" do
        2.times { described_class.query_vector("some query") }

        expect(session_double).to have_received(:embed).once
      end

      it "returns nothing for a blank query" do
        expect(described_class.query_vector("")).to be_nil
        expect(session_double).not_to have_received(:embed)
      end

      it "returns nothing when the LLM call fails" do
        allow(session_double).to receive(:embed).and_raise(Llm::Errors::ConnectionError, "timeout")

        expect(described_class.query_vector("some query")).to be_nil
      end
    end
  end
end
