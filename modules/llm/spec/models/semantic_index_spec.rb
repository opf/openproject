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

RSpec.describe SemanticIndex do
  include_context "with an embedding model offered"

  subject(:semantic_index) { build(:semantic_index) }

  it "starts out as not indexed" do
    expect(semantic_index.save).to be(true)
    expect(semantic_index.reload).to be_not_indexed
  end

  it "requires a title" do
    semantic_index.title = ""

    expect(semantic_index).not_to be_valid
    expect(semantic_index.errors.details[:title]).to include(error: :blank)
  end

  %i[embedding_vector_dimensions context_token_length].each do |attribute|
    it "requires a positive integer #{attribute}" do
      semantic_index.public_send(:"#{attribute}=", 0)

      expect(semantic_index).not_to be_valid
      expect(semantic_index.errors.details[attribute]).to include(a_hash_including(error: :greater_than))
    end
  end

  it "rejects a chat model" do
    semantic_index.model_id = "qwen3.6-27b"

    expect(semantic_index).not_to be_valid
    expect(semantic_index.errors.details[:model_id]).to include(error: :not_offered)
  end

  it "keeps a stored model that is no longer offered" do
    semantic_index.save!
    connection.capability_verdicts.destroy_all

    semantic_index.title = "Renamed"

    expect(semantic_index).to be_valid
  end
end
