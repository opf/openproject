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

RSpec.describe Projects::CreationWizard do
  shared_let(:status) { create(:status) }
  shared_let(:type) { create(:type) }
  shared_let(:workflow) { create(:workflow, old_status: status, type:) }

  let(:project) { create(:project, types: [type]) }

  describe "#project_creation_wizard_artifact_name" do
    context "when no value is stored" do
      it "returns the default artifact name" do
        expect(project.project_creation_wizard_artifact_name).to eq("project_creation_wizard")
      end
    end

    context "when the stored value is nil" do
      before { project.update_column(:settings, project.settings.merge("project_creation_wizard_artifact_name" => nil)) }

      it "returns the default artifact name" do
        project.reload
        expect(project.project_creation_wizard_artifact_name).to eq("project_creation_wizard")
      end
    end

    context "when a value is stored" do
      before { project.project_creation_wizard_artifact_name = "project_initiation_request" }

      it "returns the stored value" do
        expect(project.project_creation_wizard_artifact_name).to eq("project_initiation_request")
      end
    end
  end

  describe "#project_creation_wizard_work_package_type_id" do
    context "when no value is stored" do
      it "returns the id of the first project type" do
        expect(project.project_creation_wizard_work_package_type_id).to eq(type.id)
      end
    end

    context "when the stored value is nil" do
      before do
        project.update_column(:settings, project.settings.merge("project_creation_wizard_work_package_type_id" => nil))
      end

      it "returns the id of the first project type" do
        project.reload
        expect(project.project_creation_wizard_work_package_type_id).to eq(type.id)
      end
    end

    context "when a value is stored" do
      let(:other_type) { create(:type) }

      before { project.project_creation_wizard_work_package_type_id = other_type.id }

      it "returns the stored value" do
        expect(project.project_creation_wizard_work_package_type_id).to eq(other_type.id)
      end
    end
  end

  describe "#project_creation_wizard_status_when_submitted_id" do
    context "when no value is stored" do
      it "returns the id of the first status of the first project type" do
        expect(project.project_creation_wizard_status_when_submitted_id).to eq(status.id)
      end
    end

    context "when the stored value is nil" do
      before do
        project.update_column(:settings,
                              project.settings.merge("project_creation_wizard_status_when_submitted_id" => nil))
      end

      it "returns the id of the first status of the first project type" do
        project.reload
        expect(project.project_creation_wizard_status_when_submitted_id).to eq(status.id)
      end
    end

    context "when a value is stored" do
      let(:other_status) { create(:status) }

      before { project.project_creation_wizard_status_when_submitted_id = other_status.id }

      it "returns the stored value" do
        expect(project.project_creation_wizard_status_when_submitted_id).to eq(other_status.id)
      end
    end
  end
end
