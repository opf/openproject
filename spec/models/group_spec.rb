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
require_relative "../support/shared/become_member"

RSpec.describe Group do
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:watcher) { create(:user) }
  let(:project) { create(:project_with_types) }
  let(:status) { create(:status) }
  let(:package) do
    build(:work_package, type: project.types.first,
                         author: user,
                         project:,
                         status:)
  end

  it "creates" do
    g = described_class.new(lastname: "New group")
    expect(g.save).to be true
  end

  describe "with long but allowed attributes" do
    it "is valid" do
      group.name = "a" * 256
      expect(group).to be_valid
      expect(group.save).to be_truthy
    end
  end

  describe "with a name too long" do
    it "is invalid" do
      group.name = "a" * 257
      expect(group).not_to be_valid
      expect(group.save).to be_falsey
    end
  end

  describe "a user with and overly long firstname (> 256 chars)" do
    it "is invalid" do
      user.firstname = "a" * 257
      expect(user).not_to be_valid
      expect(user.save).to be_falsey
    end
  end

  describe "#group_users" do
    context "when adding a user" do
      context "if it does not exist" do
        it "does not create a group user" do
          count = group.group_users.count
          gu = group.group_users.create user_id: User.maximum(:id).to_i + 1

          expect(gu).not_to be_valid
          expect(group.group_users.count).to eq count
        end
      end

      it "updates the timestamp" do
        updated_at = group.updated_at
        group.group_users.create(user:)

        expect(updated_at < group.reload.updated_at)
          .to be_truthy
      end
    end

    context "when removing a user" do
      it "updates the timestamp" do
        group.group_users.create(user:)
        updated_at = group.reload.updated_at

        group.group_users.destroy_all

        expect(updated_at < group.reload.updated_at)
          .to be_truthy
      end
    end
  end

  describe "#create" do
    describe "group with empty group name" do
      let(:group) { build(:group, lastname: "") }

      it { expect(group).not_to be_valid }

      describe "error message" do
        before do
          group.valid?
        end

        it { expect(group.errors.full_messages[0]).to include I18n.t("attributes.name") }
      end
    end
  end

  describe "preference" do
    %w{preference
       preference=
       build_preference
       create_preference
       create_preference!}.each do |method|
      it "does not respond to #{method}" do
        expect(group).not_to respond_to method
      end
    end
  end

  describe "#name" do
    it { expect(group).to validate_presence_of :name }
    it { expect(group).to validate_uniqueness_of :name }
  end

  it_behaves_like "creates an audit trail on destroy" do
    subject { create(:attachment) }
  end

  it_behaves_like "acts_as_customizable included" do
    let(:model_instance) { group }
    let(:custom_field) { create(:group_custom_field, :string) }
  end
end
