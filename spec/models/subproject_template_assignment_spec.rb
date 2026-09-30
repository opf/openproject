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

RSpec.describe SubprojectTemplateAssignment do
  let(:project) { create(:project) }
  let(:template) { create(:project, templated: true) }

  describe "associations" do
    it { is_expected.to belong_to(:project).inverse_of(:subproject_template_assignments) }
    it { is_expected.to belong_to(:template) }

    it "allows accessing assignments from project" do
      assignment = create(:subproject_template_assignment, project:, template:)

      # Need to reload through the database to pick up the new association
      expect(project.subproject_template_assignments.reload).to include(assignment)
    end
  end

  describe "enums" do
    it "defines workspace_type enum" do
      expect(described_class.workspace_types).to eq({ "project" => "project", "program" => "program" })
    end

    it "allows setting workspace_type to project" do
      assignment = build(:subproject_template_assignment, workspace_type: :project)
      expect(assignment.workspace_type).to eq("project")
      expect(assignment).to be_project
    end

    it "allows setting workspace_type to program" do
      assignment = build(:subproject_template_assignment, workspace_type: :program)
      expect(assignment.workspace_type).to eq("program")
      expect(assignment).to be_program
    end
  end

  describe "validations" do
    let(:workspace_type) { "project" }

    subject(:assignment) do
      build(:subproject_template_assignment,
            project:,
            template:,
            workspace_type:)
    end

    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:template_id) }
    it { is_expected.to validate_presence_of(:workspace_type) }

    describe "uniqueness" do
      before do
        create(:subproject_template_assignment,
               project:,
               template:,
               workspace_type: "project")
      end

      it "allows only one assignment per project and workspace_type" do
        duplicate = build(:subproject_template_assignment,
                          project:,
                          template:,
                          workspace_type: "project")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:project_id]).to include("has already been taken.")
      end

      it "allows different workspace_types for the same project" do
        different_type = build(:subproject_template_assignment,
                               project:,
                               template:,
                               workspace_type: "program")

        expect(different_type).to be_valid
      end

      it "allows same workspace_type for different projects" do
        other_project = create(:project)
        different_project = build(:subproject_template_assignment,
                                  project: other_project,
                                  template:,
                                  workspace_type: "project")

        expect(different_project).to be_valid
      end
    end

    describe "template validation" do
      context "when template is marked as templated" do
        let(:template) { create(:project, templated: true) }

        it "is valid" do
          expect(assignment).to be_valid
        end
      end

      context "when template is not marked as templated" do
        let(:template) { create(:project, templated: false) }

        it "is invalid and has template error" do
          expect(assignment).not_to be_valid
          expect(assignment.errors[:template]).to be_present
        end
      end
    end

    describe "workspace_type" do
      context "for 'project'" do
        it "is valid" do
          expect(assignment).to be_valid
        end
      end

      context "for 'program'" do
        let(:workspace_type) { "program" }

        it "is valid" do
          expect(assignment).to be_valid
        end
      end

      context "for 'portfolio'" do
        let(:workspace_type) { "portfolio" }

        it "is invalid" do
          expect(assignment).not_to be_valid
          expect(assignment.errors.symbols_for(:workspace_type)).to match [:inclusion]
        end
      end
    end
  end

  describe "cascading deletes" do
    let!(:assignment) do
      create(:subproject_template_assignment,
             project:,
             template:)
    end

    context "when project is deleted" do
      it "deletes the assignment via cascade" do
        expect { project.destroy }.to change(described_class, :count).by(-1)
      end
    end

    context "when template is deleted" do
      it "deletes the assignment via cascade" do
        expect { template.destroy }.to change(described_class, :count).by(-1)
      end
    end
  end

  describe "factory" do
    it "creates a valid assignment with default attributes" do
      assignment = create(:subproject_template_assignment)
      expect(assignment).to be_valid
      expect(assignment).to be_persisted
    end

    it "creates a valid assignment with :for_project trait" do
      assignment = create(:subproject_template_assignment, :for_project)
      expect(assignment).to be_valid
      expect(assignment.workspace_type).to eq("project")
      expect(assignment.template.workspace_type).to eq("project")
      expect(assignment.template).to be_templated
    end

    it "creates a valid assignment with :for_program trait" do
      assignment = create(:subproject_template_assignment, :for_program)
      expect(assignment).to be_valid
      expect(assignment.workspace_type).to eq("program")
      expect(assignment.template.workspace_type).to eq("program")
      expect(assignment.template).to be_templated
    end
  end
end
