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

  describe ".register" do
    it "refuses a capability the kind cannot have" do
      expect { described_class.register(key, kind: :chat, requires: %i[embeddings]) }
        .to raise_error(ArgumentError, /embeddings/)
    end

    it "refuses an unknown kind" do
      expect { described_class.register(key, kind: :completion) }
        .to raise_error(ArgumentError, /unknown kind/)
    end

    it "scopes the translations by the key unless told otherwise" do
      described_class.register(key, kind: :chat)

      expect(described_class[key].i18n_scope).to eq("llm.features.spec_only_feature")
    end
  end

  it "registers semantic search as a pinned embedding feature" do
    expect(described_class[:semantic_search])
      .to have_attributes(kind: :embedding, pinned: true, requires: %i[embeddings])
  end
end
