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

  let(:params) { {} }
  let(:extra_filters) { [] }

  context "with no filters param" do
    it "builds a valid, project-scoped query without generic filters", :aggregate_failures do
      expect(query).to be_valid
      expect(query.project).to eq(project)
      expect(query.include_subprojects?).to be false
      expect(query.filters.map(&:name)).to contain_exactly(:project_id)
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
      expect(query.filters.map(&:name)).to contain_exactly(:project_id)
    end
  end

  context "with default sorting" do
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

  describe "#build_sprint_work_packages" do
    subject(:work_packages) do
      described_class.new(project:, user:, params:).build_sprint_work_packages(sprint_ids:)
    end

    shared_let(:other_project) { create(:project) }
    shared_let(:sprint) { create(:sprint, project:) }
    shared_let(:other_sprint) { create(:sprint, project:) }
    shared_let(:own_work_package) { create(:work_package, project:, sprint:) }
    shared_let(:other_sprint_work_package) { create(:work_package, project:, sprint: other_sprint) }

    context "with no explicit sprint selection" do
      let(:sprint_ids) { [] }

      it "returns no work packages" do
        expect(work_packages).to be_empty
      end
    end

    context "with a single sprint selected" do
      let(:sprint_ids) { [sprint.id.to_s] }

      it "returns only that sprint's work packages" do
        expect(work_packages).to contain_exactly(own_work_package)
      end
    end

    context "with multiple sprints selected" do
      let(:sprint_ids) { [sprint.id.to_s, other_sprint.id.to_s] }

      it "returns work packages from all of the given sprints" do
        expect(work_packages).to contain_exactly(own_work_package, other_sprint_work_package)
      end
    end

    context "when another project's work package shares the same sprint and filters try to widen scope" do
      shared_let(:other_project_work_package) { create(:work_package, project: other_project, sprint:) }
      let(:sprint_ids) { [sprint.id.to_s] }
      let(:params) { { filters: "project_id = \"#{other_project.id}\"" } }

      it "never returns the other project's work package, regardless of the requested project filter" do
        expect(work_packages).not_to include(other_project_work_package)
      end
    end
  end

  describe "#build_backlog_work_packages" do
    subject(:work_packages) do
      described_class.new(project:, user:, params:).build_backlog_work_packages(bucket_ids:, show_inbox:)
    end

    shared_let(:other_project) { create(:project) }
    shared_let(:bucket) { create(:backlog_bucket, project:) }
    shared_let(:bucket_work_package) { create(:work_package, project:, backlog_bucket: bucket) }
    shared_let(:inbox_work_package) { create(:work_package, project:) }

    context "with no bucket selected and the inbox shown" do
      let(:bucket_ids) { [] }
      let(:show_inbox) { true }

      it "returns only the inbox work packages" do
        expect(work_packages).to contain_exactly(inbox_work_package)
      end
    end

    context "with no bucket selected and the inbox is not shown" do
      let(:bucket_ids) { [] }
      let(:show_inbox) { false }

      it "returns no work packages" do
        expect(work_packages).to be_empty
      end
    end

    context "with a bucket selected and the inbox hidden" do
      let(:bucket_ids) { [bucket.id.to_s] }
      let(:show_inbox) { false }

      it "returns only the selected bucket's work packages" do
        expect(work_packages).to contain_exactly(bucket_work_package)
      end
    end

    context "with a bucket selected and the inbox shown" do
      let(:bucket_ids) { [bucket.id.to_s] }
      let(:show_inbox) { true }

      it "returns both bucket and inbox work packages" do
        expect(work_packages).to contain_exactly(bucket_work_package, inbox_work_package)
      end
    end

    context "when another project's work package could match and filters try to widen scope" do
      shared_let(:other_bucket) { create(:backlog_bucket, project: other_project) }
      shared_let(:other_work_package) { create(:work_package, project: other_project, backlog_bucket: other_bucket) }

      let(:bucket_ids) { [] }
      let(:show_inbox) { true }
      let(:params) { { filters: "project_id = \"#{other_project.id}\"" } }

      it "never returns the other project's work package, regardless of the requested project filter" do
        expect(work_packages).not_to include(other_work_package)
      end
    end
  end
end
