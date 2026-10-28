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

RSpec.describe LlmCapabilityVerdict do
  let(:connection) { create(:llm_connection) }

  describe "validations" do
    it "allows one verdict per capability of a model on a connection" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "embeddings")

      expect(build(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "embeddings"))
        .not_to be_valid
      expect(build(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "vision"))
        .to be_valid
      expect(build(:llm_capability_verdict, model_id: "bge-m3", capability: "embeddings")).to be_valid
    end

    it "refuses a state or source outside the known ones" do
      expect(build(:llm_capability_verdict, state: "maybe")).not_to be_valid
      expect(build(:llm_capability_verdict, source: "rumour")).not_to be_valid
    end

    it "requires a model and a capability" do
      expect(build(:llm_capability_verdict, model_id: "")).not_to be_valid
      expect(build(:llm_capability_verdict, capability: "")).not_to be_valid
    end
  end

  describe "blocking" do
    let!(:unsupported) do
      create(:llm_capability_verdict, llm_connection: connection, capability: "embeddings", state: "unsupported")
    end

    before do
      create(:llm_capability_verdict, llm_connection: connection, capability: "embeddings", state: "unknown")
      create(:llm_capability_verdict, llm_connection: connection, capability: "vision", state: "unsupported")
    end

    it "is caused by an unsupported verdict only" do
      expect(unsupported).to be_blocking
      expect(build(:llm_capability_verdict, state: "unknown")).not_to be_blocking
    end

    it "selects the unsupported verdicts for the required capabilities" do
      expect(connection.capability_verdicts.blocking(%i[embeddings])).to contain_exactly(unsupported)
    end
  end

  describe ".sticky" do
    it "selects an administrator's assertions" do
      admin = create(:llm_capability_verdict, llm_connection: connection, source: "admin")
      create(:llm_capability_verdict, llm_connection: connection, source: "probe")

      expect(connection.capability_verdicts.sticky).to contain_exactly(admin)
    end
  end

  describe "#dimensions" do
    it "reads the dimensions a probe recorded" do
      expect(build(:llm_capability_verdict, detail: { "dimensions" => 1024 }).dimensions).to eq(1024)
      expect(build(:llm_capability_verdict).dimensions).to be_nil
    end
  end
end
