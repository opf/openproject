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

require "rails_helper"

RSpec.describe Backlogs::BacklogQueryBuilder do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }

  before { login_as(user) }

  subject(:query) { described_class.new(project:, user:, params:).build(extra_filters:) }

  let(:extra_filters) { [] }

  context "with no filters param" do
    let(:params) { {} }

    it "builds a valid, project-scoped query without generic filters", :aggregate_failures do
      expect(query).to be_valid
      expect(query.project).to eq(project)
      expect(query.include_subprojects?).to be false
      expect(query.filters).to be_empty
    end
  end

  context "with a params-format filters param" do
    shared_let(:status) { create(:status) }
    let(:params) { { filters: "status_id = \"#{status.id}\"" } }

    it "applies the parsed filter to the query", :aggregate_failures do
      filter = query.find_active_filter(:status_id)

      expect(filter).to be_present
      expect(filter.operator).to eq("=")
      expect(filter.values).to eq([status.id.to_s])
    end
  end

  context "with a subject search filter" do
    let(:params) { { filters: 'subject ~ "foo"' } }

    it "survives valid_subset! and remains active", :aggregate_failures do
      filter = query.find_active_filter(:subject)

      expect(filter).to be_present
      expect(filter.values).to eq(["foo"])
    end
  end

  context "with a malformed filters param" do
    let(:params) { { filters: "not json" } }

    it "ignores it and builds a query without generic filters" do
      expect(query.filters).to be_empty
    end
  end

  context "with default sorting" do
    let(:params) { {} }

    it "sorts by position (with id as a tiebreak)" do
      expect(query.sort_criteria).to eq([%w[position asc], %w[id asc]])
    end
  end

  context "with extra_filters" do
    shared_let(:sprint) { create(:sprint, project:) }
    let(:params) { {} }
    let(:extra_filters) { [[:sprint_id, "=", [sprint.id.to_s]]] }

    it "applies them onto the query" do
      filter = query.find_active_filter(:sprint_id)

      expect(filter.values).to eq([sprint.id.to_s])
    end
  end
end
