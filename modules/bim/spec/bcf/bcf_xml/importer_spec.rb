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

RSpec.describe OpenProject::Bim::BcfXml::Importer do
  let(:filename) { "MaximumInformation.bcf" }
  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("modules/bim/spec/fixtures/files/#{filename}").to_s,
      "application/octet-stream"
    )
  end
  let(:type) { create(:type, name: "Issue", is_standard: true, is_default: true) }
  let(:project) do
    create(:project,
           identifier: "bim_project",
           enabled_module_names: %w[bim work_package_tracking],
           types: [type])
  end
  let(:member_role) do
    create(:project_role,
           permissions: %i[view_linked_issues view_work_packages])
  end
  let(:manage_bcf_role) do
    create(
      :project_role,
      permissions: %i[manage_bcf view_linked_issues view_work_packages edit_work_packages add_work_packages]
    )
  end
  let(:bcf_manager) { create(:user) }
  let(:workflow) do
    create(:workflow_with_default_status,
           role: manage_bcf_role,
           type:)
  end
  let(:priority) { create(:default_priority) }
  let(:bcf_manager_member) do
    create(:member,
           project:,
           user: bcf_manager,
           roles: [manage_bcf_role, member_role])
  end

  subject { described_class.new file, project, current_user: bcf_manager }

  before do
    workflow
    priority
    bcf_manager_member
  end

  describe "#to_listing" do
    context "without sufficient permissions" do
      context "no add_work_packages permission" do
        pending "test that importing user has add_work_packages permission"
      end

      context "no manage_members permission" do
        pending "test that non members should not be able to prepare an import"
      end
    end
  end

  describe "#import!" do
    it "imports successfully" do
      expect(subject.import!).to be_present
    end

    it "creates 2 work packages" do
      subject.import!

      expect(Bim::Bcf::Issue.count).to eql 2
      expect(WorkPackage.count).to eql 2
    end
  end

  context "with a viewpoint and snapshot" do
    let(:filename) { "issue-with-viewpoint.bcf" }

    it "imports that viewpoint successfully" do
      expect(subject.import!).to be_present

      expect(Bim::Bcf::Issue.count).to eq 1
      issue = Bim::Bcf::Issue.last
      expect(issue.viewpoints.count).to eq 1

      viewpoint = issue.viewpoints.first
      expect(viewpoint.attachments.count).to eq 1
      expect(viewpoint.snapshot).to be_present
    end
  end
end
