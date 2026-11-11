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

RSpec.describe ITSM::HelpdeskUsers::SetUpService do
  subject(:result) { described_class.new.call }

  let(:user) { ITSM.helpdesk_user }
  let(:role) { ITSM.helpdesk_role }

  it "creates a service account named after the help desk" do
    expect(result).to be_success
    expect(user).to be_a(ServiceAccount)
    expect(user).to have_attributes(name: "Help desk", admin: false, status: "active")
  end

  it "creates a role that can create and comment on work packages" do
    result

    expect(role).to have_attributes(name: "Help desk")
    expect(role.permissions).to match_array(%i[view_work_packages add_work_packages add_work_package_comments])
  end

  it "remembers the account and the role" do
    result

    expect(Setting.helpdesk_user_id).to eq(user.id)
    expect(Setting.helpdesk_role_id).to eq(role.id)
  end

  it "does not count the account as a user of the instance" do
    result

    expect(User.human).not_to include(user)
    expect(Principal.not_builtin).not_to include(user)
  end

  context "when the account and the role exist" do
    let!(:existing_user) { described_class.new.call.then { ITSM.helpdesk_user } }

    it "keeps the existing account without creating anything" do
      expect { result }.not_to change(Principal, :count)
      expect(user).to eq(existing_user)
      expect(ProjectRole.where(name: "Help desk").count).to eq(1)
    end

    it "does not take the lock" do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock)

      result

      expect(OpenProject::Mutex).not_to have_received(:with_advisory_lock)
    end
  end

  context "when the account cannot be saved" do
    before do
      allow(I18n).to receive(:t).and_call_original
      allow(I18n).to receive(:t).with(:label_helpdesk_user, any_args).and_return("")
    end

    it "rolls back the role, also inside another transaction" do
      outer_result = ActiveRecord::Base.transaction { result }

      expect(outer_result).to be_failure
      expect(outer_result.errors.symbols_for(:name)).to eq([:blank])
      expect(ProjectRole.where(name: "Help desk")).not_to exist
    end
  end

  context "when the account was deleted" do
    let!(:existing_user) { described_class.new.call.then { ITSM.helpdesk_user } }

    before { existing_user.destroy }

    it "creates a new one and keeps the role" do
      expect { result }.not_to change(ProjectRole, :count)
      expect(user).to be_persisted
      expect(user).not_to eq(existing_user)
    end
  end

  context "when another role already has the name" do
    before { create(:project_role, name: "Help desk") }

    it "fails without creating the account" do
      expect { result }.not_to change(Principal, :count)
      expect(result).to be_failure
      expect(result.errors.symbols_for(:name)).to eq([:taken])
    end
  end

  context "when the configured role does not exist", :settings_reset do
    before { Settings::Definition[:helpdesk_role_id].override_value(0) }

    it "fails without creating anything" do
      expect { result }.not_to change(Principal, :count)
      expect(result).to be_failure
      expect(result.message).to eq("OPENPROJECT_HELPDESK__ROLE__ID is set to 0, but nothing with that id exists.")
      expect(ProjectRole.where(name: "Help desk")).not_to exist
    end
  end

  context "when the configured account does not exist", :settings_reset do
    before { Settings::Definition[:helpdesk_user_id].override_value(0) }

    it "fails and rolls back the role" do
      expect(result).to be_failure
      expect(result.message).to eq("OPENPROJECT_HELPDESK__USER__ID is set to 0, but nothing with that id exists.")
      expect(ProjectRole.where(name: "Help desk")).not_to exist
    end
  end
end
