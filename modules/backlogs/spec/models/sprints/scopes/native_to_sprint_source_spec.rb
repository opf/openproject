# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Sprints::Scopes::NativeToSprintSource do
  let(:sprint_sharing) { "no_sharing" }
  let(:project) { create(:project, sprint_sharing:) }
  let(:global_sharer) { create(:project, sprint_sharing: "share_all_projects") }
  let(:other_project) { create(:project) }
  let!(:sprint_in_project) { create(:sprint, project:) }
  let!(:global_sprint) { create(:sprint, project: global_sharer) }
  let!(:sprint_in_other_project) { create(:sprint, project: other_project) }

  shared_examples "executes a single SQL query" do
    it "resolves native_to_sprint_source in a single query" do
      expect { Sprint.native_to_sprint_source(project).load }.to have_a_query_limit(1)
    end
  end

  describe ".native_to_sprint_source" do
    context "when project does not receive sprints (no_sharing)" do
      let(:sprint_sharing) { "no_sharing" }

      it_behaves_like "executes a single SQL query"

      context "and there are no work package assignments" do
        it "returns only the project's own sprint" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(sprint_in_project)
        end
      end

      context "and the project has a work package assigned to a sprint from another project" do
        let!(:cross_project_sprint) { create(:sprint, project: other_project) }
        let!(:work_package) { create(:work_package, project:, sprint: cross_project_sprint) }

        it "returns only the project's own sprint" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(sprint_in_project)
        end

        context "when the cross-project sprint is completed" do
          let!(:completed_sprint) { create(:sprint, project: other_project, status: "completed") }
          let!(:work_package) { create(:work_package, project:, sprint: completed_sprint) }

          it "returns only the project's own sprint" do
            expect(Sprint.native_to_sprint_source(project)).to contain_exactly(sprint_in_project)
          end
        end
      end
    end

    context "when project is a sender (share_subprojects)" do
      let(:sprint_sharing) { "share_subprojects" }

      it_behaves_like "executes a single SQL query"

      context "and there are no work package assignments" do
        it "returns only the project's own sprint" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(sprint_in_project)
        end
      end

      context "and a work package in the project is assigned to a sprint from another project" do
        let!(:cross_project_sprint) { create(:sprint, project: other_project) }
        let!(:work_package) { create(:work_package, project:, sprint: cross_project_sprint) }

        it "returns only the project's own sprint" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(sprint_in_project)
        end
      end
    end

    context "when project is a sender (share_all_projects)" do
      let(:sprint_sharing) { "share_all_projects" }

      it_behaves_like "executes a single SQL query"

      context "and there are no work package assignments" do
        it "returns only the project's own sprint" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(sprint_in_project)
        end
      end

      context "and a work package in the project is assigned to a sprint from another project" do
        let!(:cross_project_sprint) { create(:sprint, project: other_project) }
        let!(:work_package) { create(:work_package, project:, sprint: cross_project_sprint) }

        it "returns only the project's own sprint" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(sprint_in_project)
        end
      end
    end

    context "when project receives shared sprints" do
      let(:sprint_sharing) { "receive_shared" }

      it_behaves_like "executes a single SQL query"

      context "and there is only a global sharer" do
        it "returns only the sprints shared from the global sharer project" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(global_sprint)
        end

        context "and a work package is assigned to the project's own sprint" do
          let!(:work_package) { create(:work_package, project:, sprint: sprint_in_project) }

          it "returns only the sprints shared from the global sharer project" do
            expect(Sprint.native_to_sprint_source(project)).to contain_exactly(global_sprint)
          end
        end

        context "and a work package is assigned to the shared sprint from the global sharer" do
          let!(:work_package) { create(:work_package, project:, sprint: global_sprint) }

          it "returns the shared sprint only once" do
            expect(Sprint.native_to_sprint_source(project)).to contain_exactly(global_sprint)
          end
        end

        context "and a work package is assigned to a sprint from an unrelated project" do
          let!(:work_package) { create(:work_package, project:, sprint: sprint_in_other_project) }

          it "returns only the sprints shared from the global sharer project" do
            expect(Sprint.native_to_sprint_source(project)).to contain_exactly(global_sprint)
          end
        end
      end

      context "and there is a subproject-sharing ancestor" do
        let(:subproject_sharer) { create(:project, sprint_sharing: "share_subprojects") }
        let(:project) { create(:project, parent: subproject_sharer, sprint_sharing:) }
        let!(:subproject_sprint) { create(:sprint, project: subproject_sharer) }

        it "returns only the sprints shared from the closest subproject-sharing ancestor" do
          expect(Sprint.native_to_sprint_source(project)).to contain_exactly(subproject_sprint)
        end

        context "and a work package is assigned to the project's own sprint" do
          let!(:work_package) { create(:work_package, project:, sprint: sprint_in_project) }

          it "returns only the sprints shared from the closest subproject-sharing ancestor" do
            expect(Sprint.native_to_sprint_source(project)).to contain_exactly(subproject_sprint)
          end
        end

        context "and a work package is assigned to the ancestor's shared sprint" do
          let!(:work_package) { create(:work_package, project:, sprint: subproject_sprint) }

          it "returns the ancestor's shared sprint only once" do
            expect(Sprint.native_to_sprint_source(project)).to contain_exactly(subproject_sprint)
          end
        end

        context "and a work package is assigned to a sprint from the global sharer" do
          let!(:work_package) { create(:work_package, project:, sprint: global_sprint) }

          it "returns only the sprints shared from the closest subproject-sharing ancestor" do
            expect(Sprint.native_to_sprint_source(project)).to contain_exactly(subproject_sprint)
          end
        end
      end
    end
  end
end
