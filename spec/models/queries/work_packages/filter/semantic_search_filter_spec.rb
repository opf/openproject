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

RSpec.describe Queries::WorkPackages::Filter::SemanticSearchFilter do
  let(:instance) { described_class.create!(name: :semantic_search, operator: "**", values: ["login problems"]) }

  shared_let(:open_status) { create(:status, is_closed: false) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:similar_open) { create(:work_package, status: open_status) }
  shared_let(:similar_closed) { create(:work_package, status: closed_status) }
  shared_let(:unrelated) { create(:work_package, status: open_status) }

  before do
    allow(Search::SemanticResult).to receive(:ranked_ids).with("login problems")
                                                         .and_return([similar_closed.id, similar_open.id])
  end

  describe "#available?" do
    it "follows the availability of semantic search" do
      allow(Search::SemanticResult).to receive(:available?).and_return(false)
      expect(instance).not_to be_available

      allow(Search::SemanticResult).to receive(:available?).and_return(true)
      expect(instance).to be_available
    end
  end

  describe "#where" do
    it "restricts to the semantically similar work packages" do
      expect(WorkPackage.where(instance.where)).to contain_exactly(similar_open, similar_closed)
    end

    it "matches nothing when there are no similar work packages" do
      allow(Search::SemanticResult).to receive(:ranked_ids).and_return([])

      expect(WorkPackage.where(instance.where)).to be_empty
    end
  end

  describe "in a query" do
    let(:admin) { create(:admin) }
    let(:query) do
      build(:query, project: nil, user: admin).tap do |query|
        query.add_filter("semantic_search", "**", ["login problems"])
        query.add_filter("status_id", "o", [])
        query.sort_criteria = [%w[semantic_similarity asc]]
      end
    end

    before do
      allow(Search::SemanticResult).to receive(:available?).and_return(true)
      login_as(admin)
    end

    it "combines with other filters" do
      expect(query.results.work_packages).to contain_exactly(similar_open)
    end
  end
end
