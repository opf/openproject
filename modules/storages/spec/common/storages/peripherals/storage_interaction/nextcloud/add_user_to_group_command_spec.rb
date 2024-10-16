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
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::AddUserToGroupCommand, :webmock do
  include NextcloudGroupUserHelper

  let(:storage) { create(:nextcloud_storage_with_local_connection, :as_automatically_managed, username: "vcr") }
  let(:auth_strategy) { Storages::Peripherals::Registry.resolve("nextcloud.authentication.userless").call }

  describe "basic command setup" do
    it "is registered as commands.add_user_to_group" do
      expect(Storages::Peripherals::Registry
               .resolve("#{storage}.commands.add_user_to_group")).to eq(described_class)
    end

    it "responds to #call with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                   %i[keyreq auth_strategy],
                                                   %i[keyreq user],
                                                   %i[keyreq group])
    end
  end

  shared_examples_for "failing request" do |error_code:|
    it "returns a failure" do
      result = described_class.call(storage:, auth_strategy:, user:, group:)
      expect(result).to be_failure

      error = result.errors
      expect(error.code).to eq(error_code)
      expect(error.data.source).to eq(described_class)
    end
  end

  context "if group exists", vcr: "nextcloud/add_user_to_group_success" do
    let(:user) { "m.jade@death.star" }
    let(:group) { "Sith Assassins" }

    before do
      create_group(auth, storage, group)
    end

    after do
      remove_group(auth, storage, group)
    end

    it "returns a success" do
      members = group_members(group)
      expect(members).not_to include(user)

      result = described_class.call(storage:, auth_strategy:, user:, group:)
      expect(result).to be_success

      members = group_members(group)
      expect(members).to include(user)
    end
  end

  context "if target group does not exist", vcr: "nextcloud/add_user_to_group_not_existing_group" do
    let(:user) { "m.jade@death.star" }
    let(:group) { "Sith Assassins" }

    it_behaves_like "failing request", error_code: :group_does_not_exist
  end

  context "if user does not exist", vcr: "nextcloud/add_user_to_group_not_existing_user" do
    let(:user) { "this is not the user you are looking for" }
    let(:group) { "Sith Assassins" }

    before do
      create_group(auth, storage, group)
    end

    after do
      remove_group(auth, storage, group)
    end

    it_behaves_like "failing request", error_code: :user_does_not_exist
  end

  private

  def auth = Storages::Peripherals::StorageInteraction::Authentication[auth_strategy]

  def group_members(group)
    Storages::Peripherals::StorageInteraction::Nextcloud::GroupUsersQuery
      .call(storage:, auth_strategy:, group:)
      .result
  end
end
