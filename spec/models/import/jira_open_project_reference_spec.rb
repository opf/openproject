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

RSpec.describe Import::JiraOpenProjectReference do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }

  subject(:reference) { create(:jira_open_project_reference, jira:, jira_import:) }

  describe "associations" do
    it { is_expected.to belong_to(:jira).class_name("Import::Jira") }
    it { is_expected.to belong_to(:jira_import).class_name("Import::JiraImport") }
  end

  describe "#op_leg" do
    context "when op_entity exists" do
      let(:user) { create(:user) }
      let(:reference) do
        create(:jira_open_project_reference,
               jira:,
               jira_import:,
               op_entity_id: user.id.to_s,
               op_entity_class: "User")
      end

      it "returns the OpenProject entity" do
        expect(reference.op_leg).to eq(user)
      end
    end

    context "when op_entity does not exist" do
      let(:reference) do
        create(:jira_open_project_reference,
               jira:,
               jira_import:,
               op_entity_id: "999999",
               op_entity_class: "User")
      end

      it "raises an error with descriptive message" do
        expect { reference.op_leg }.to raise_error("User with id 999999 not found!")
      end
    end

    context "when op_entity_class is nil" do
      let(:reference) do
        create(:jira_open_project_reference,
               jira:,
               jira_import:,
               op_entity_id: "123",
               op_entity_class: nil)
      end

      it "returns nil" do
        expect(reference.op_leg).to be_nil
      end
    end
  end

  describe "#jira_leg" do
    context "when jira_entity exists" do
      let(:jira_user) { create(:jira_user, jira:, jira_import:) }
      let(:reference) do
        create(:jira_open_project_reference,
               jira:,
               jira_import:,
               jira_entity_id: jira_user.id.to_s,
               jira_entity_class: "Import::JiraUser")
      end

      it "returns the Jira entity" do
        expect(reference.jira_leg).to eq(jira_user)
      end
    end

    context "when jira_entity does not exist" do
      let(:reference) do
        create(:jira_open_project_reference,
               jira:,
               jira_import:,
               jira_entity_id: "999999",
               jira_entity_class: "Import::JiraUser")
      end

      it "raises an error with descriptive message" do
        expect { reference.jira_leg }.to raise_error("Import::JiraUser with id 999999 not found!")
      end
    end

    context "when jira_entity_class is nil" do
      let(:reference) do
        create(:jira_open_project_reference,
               jira:,
               jira_import:,
               jira_entity_id: "123",
               jira_entity_class: nil)
      end

      it "returns nil" do
        expect(reference.jira_leg).to be_nil
      end
    end
  end
end
