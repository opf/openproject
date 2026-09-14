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

RSpec.describe Import::JiraCreateProjectRoleJob do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }

  describe "#perform" do
    it "creates the JiraMember role with the permissions needed by the import" do
      expect { described_class.perform_now(jira_import.id) }.to change(Role, :count).by(1)

      role = Role.find_by!(name: "JiraMember")
      expect(role.permissions).to include(:add_work_packages,
                                          :view_work_packages,
                                          :add_work_package_comments,
                                          :add_work_package_attachments,
                                          :work_package_assigned)
    end

    it "creates a reference for the new role" do
      expect { described_class.perform_now(jira_import.id) }
        .to change(Import::JiraOpenProjectReference, :count).by(1)

      reference = Import::JiraOpenProjectReference.last
      expect(reference).to have_attributes(
        op_entity_class: "ProjectRole",
        jira_entity_id: nil,
        jira_entity_class: nil,
        jira_import_id: jira_import.id,
        uses_existing: false
      )
    end

    context "when the role already exists" do
      before { described_class.perform_now(jira_import.id) }

      it "does not create another role" do
        expect { described_class.perform_now(jira_import.id) }.not_to change(Role, :count)
      end
    end

    context "when role creation fails for another reason" do
      before do
        allow(Roles::CreateService).to receive(:new).and_return(
          instance_double(Roles::CreateService,
                          call: ServiceResult.failure(message: "Something went wrong"))
        )
      end

      it "raises the error message" do
        expect { described_class.perform_now(jira_import.id) }.to raise_error("Something went wrong")
      end
    end
  end
end
