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
require_module_spec_helper

RSpec.describe ITSM::HelpdeskUsers::AddToProjectService, with_flag: { helpdesk: true } do
  subject(:result) { described_class.new.call(project:) }

  let(:project) { create(:project, disable_modules: :helpdesk) }
  let(:member) { Member.find_by(project:, principal: ITSM.helpdesk_user) }

  it "makes the help desk user a member with the help desk role" do
    expect(result).to be_success
    expect(member.roles).to contain_exactly(ITSM.helpdesk_role)
  end

  context "when the help desk user cannot be created" do
    before { create(:project_role, name: "Help desk") }

    it "fails without adding a member" do
      expect(result).to be_failure
      expect(Member.where(project:)).to be_empty
    end
  end

  context "when the help desk user is already a member with the role" do
    before { described_class.new.call(project:) }

    it "changes nothing" do
      expect { result }.not_to change(MemberRole, :count)
      expect(result).to be_success
      expect(result.result).not_to be_changed_for_autosave
    end
  end

  context "when the help desk user is a member with other roles" do
    let(:other_role) { create(:project_role) }
    let(:helpdesk_user) { ITSM::HelpdeskUsers::FindOrCreateService.new.call.result }

    before { create(:member, project:, principal: helpdesk_user, roles: [other_role]) }

    it "adds the help desk role and keeps the others" do
      expect(result).to be_success
      expect(member.roles).to contain_exactly(other_role, ITSM.helpdesk_role)
    end
  end
end
