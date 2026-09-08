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

RSpec.describe OpenProject::Llm::Features do
  let(:key) { :spec_only_feature }

  after { described_class.all.delete(key) }

  describe "prefixes" do
    it "derives them from the key of an embedding feature" do
      described_class.register(key, kind: :embedding, requires: %i[embeddings])

      expect(described_class[key].input_prefix).to eq("spec_only_feature_")
      expect(described_class[key].query_prefix).to eq("spec_only_feature_")
    end

    it "keeps the ones a feature names itself" do
      described_class.register(key, kind: :embedding, input_prefix: "passage: ", query_prefix: "query: ")

      expect(described_class[key].input_prefix).to eq("passage: ")
      expect(described_class[key].query_prefix).to eq("query: ")
    end

    it "leaves a chat feature without any" do
      described_class.register(key, kind: :chat)

      expect(described_class[key].input_prefix).to be_nil
      expect(described_class[key].query_prefix).to be_nil
    end

    it "refuses one on a chat feature" do
      expect { described_class.register(key, kind: :chat, input_prefix: "passage: ") }
        .to raise_error(ArgumentError, /chat feature/)
    end

    it "presets the ones semantic search is registered with" do
      expect(described_class[:semantic_search].input_prefix).to eq("semantic_search_")
    end
  end
end
