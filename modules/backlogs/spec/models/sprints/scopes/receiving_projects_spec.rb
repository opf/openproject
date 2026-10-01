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

RSpec.describe Sprints::Scopes::ReceivingProjects do
  let(:source_project) { create(:project, sprint_sharing: source_sharing) }
  let(:source_sharing) { "no_sharing" }
  let(:sprint) { create(:sprint, project: source_project) }

  describe ".receiving_projects" do
    subject(:scope) { Sprint.receiving_projects(sprint) }

    it "resolves in a single query" do
      sprint

      expect { scope.load }.to have_a_query_limit(1)
    end

    context "when the sprint is not shared" do
      it "returns only the source project" do
        expect(scope).to contain_exactly(source_project)
      end
    end

    context "when the sprint source shares with all projects" do
      let(:source_sharing) { "share_all_projects" }
      let!(:receiving_project) { create(:project, sprint_sharing: "receive_shared") }
      let!(:other_project) { create(:project) }

      it "includes receiving projects even without local sprint work packages" do
        expect(scope).to contain_exactly(source_project, receiving_project)
      end
    end

    context "when an ancestor shares subprojects (blocking share_all_projects)" do
      let(:source_sharing) { "share_all_projects" }
      let!(:ancestor_sharer) { create(:project, sprint_sharing: "share_subprojects") }
      let!(:blocked_receiver) do
        create(:project, parent: ancestor_sharer, sprint_sharing: "receive_shared")
      end
      let!(:unblocked_receiver) { create(:project, sprint_sharing: "receive_shared") }

      it "excludes receivers beneath the share_subprojects ancestor" do
        expect(scope).to contain_exactly(source_project, unblocked_receiver)
      end
    end

    context "when the sprint source shares with subprojects" do
      let(:source_sharing) { "share_subprojects" }
      let!(:receiving_project) do
        create(:project, parent: source_project, sprint_sharing: "receive_shared")
      end
      let!(:deeper_receiver) do
        create(:project, parent: receiving_project, sprint_sharing: "receive_shared")
      end
      let!(:other_receiver) { create(:project, sprint_sharing: "receive_shared") }

      it "includes descendant receivers of the source project" do
        expect(scope).to contain_exactly(source_project, receiving_project, deeper_receiver)
      end
    end

    context "when a closer ancestor shares subprojects" do
      let(:source_sharing) { "share_subprojects" }
      let!(:child_sharer) do
        create(:project, parent: source_project, sprint_sharing: "share_subprojects")
      end
      let!(:receiving_project) do
        create(:project, parent: child_sharer, sprint_sharing: "receive_shared")
      end

      it "does not include receivers that resolve to the closer ancestor" do
        expect(scope).to contain_exactly(source_project)
      end
    end

    context "when work packages exist in additional projects" do
      let!(:work_package_project) { create(:project) }

      before do
        create(:work_package, project: work_package_project, sprint:)
      end

      it "includes work package projects in addition to sharing receivers" do
        expect(scope).to contain_exactly(source_project, work_package_project)
      end
    end
  end
end
