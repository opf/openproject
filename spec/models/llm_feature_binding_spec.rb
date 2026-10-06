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

RSpec.describe LlmFeatureBinding do
  let(:connection) { create(:llm_connection, :with_models) }

  def bind(model_id)
    connection.feature_bindings.new(feature_key: "description_assistant", model_id:)
  end

  describe "the bound model" do
    it "may be one the connection offers" do
      expect(bind("qwen3.6-27b")).to be_valid
    end

    it "may be left blank to inherit the connection default" do
      expect(bind(nil)).to be_valid
    end

    it "must be one the connection offers" do
      binding = bind("no-such-model")

      expect(binding).not_to be_valid
      expect(binding.errors.details[:model_id]).to include(error: :not_available)
    end

    it "must not be one an administrator switched off" do
      connection.models.find_by!(external_id: "qwen3.6-27b").update!(active: false)

      expect(bind("qwen3.6-27b")).not_to be_valid
    end

    # A catalogue that shrinks underneath a stored binding must not block every
    # later save of it; the page flags the binding as dangling instead.
    it "is not checked again while it stays the same" do
      binding = bind("qwen3.6-27b").tap(&:save!)
      connection.models.find_by!(external_id: "qwen3.6-27b").update!(active: false)

      expect(binding.reload).to be_valid
    end

    it "reports a missing connection instead of raising" do
      binding = described_class.new(feature_key: "description_assistant", model_id: "qwen3.6-27b")

      expect(binding).not_to be_valid
      expect(binding.errors.details[:llm_connection]).to include(error: :blank)
    end
  end

  describe "inheriting the connection default" do
    let(:connection) do
      create(:llm_connection, :with_models,
             default_chat_model_identifier: "qwen3.6-27b",
             default_embedding_model_identifier: "bge-m3")
    end

    it "resolves to the identifier the server knows the default model by" do
      binding = bind(nil).tap(&:save!)

      expect(binding.resolved_model_id).to eq("qwen3.6-27b")
      expect(binding).not_to be_dangling
    end

    it "writes that identifier down when the binding is locked" do
      binding = connection.feature_bindings.create!(feature_key: "semantic_search")

      binding.update!(locked_at: Time.current)

      expect(binding.reload.model_id).to eq("bge-m3")
    end
  end
end
