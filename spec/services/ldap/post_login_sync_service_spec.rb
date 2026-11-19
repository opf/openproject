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

RSpec.describe Ldap::PostLoginSyncService do
  let!(:ldap) { create(:ldap_auth_source) }
  let(:admin) { false }
  let(:attributes) do
    {
      login: "aa729",
      admin:,
      firstname: "Alexandra",
      lastname: "Adams",
      mail: "a.adam@example.com",
      ldap_auth_source_id: ldap.id
    }
  end

  subject do
    described_class.new(ldap, user:, attributes:).call
  end

  context "with an existing user" do
    let!(:user) { create(:user, firstname: "Bob", lastname: "Bobbit", mail: "b@example.com", login: "aa729") }

    it "syncs the attributes" do
      expect(user.firstname).to eq "Bob"
      expect(user.lastname).to eq "Bobbit"
      expect(user.mail).to eq "b@example.com"

      expect(subject).to be_success
      expect(subject.result).to be_a User
      expect(subject.result).to eq user.reload
      expect(subject.result).to be_valid
      expect(subject.result.firstname).to eq "Alexandra"
      expect(subject.result.lastname).to eq "Adams"
      expect(subject.result.mail).to eq "a.adam@example.com"
    end

    context "with nil attributes" do
      let(:attributes) { nil }

      it "locks the user when enabled", with_config: { ldap_users_sync_status: true } do
        expect(user).to be_active

        subject

        expect(user.reload).to be_locked
      end

      it "does nothing when not enabled", with_config: { ldap_users_sync_status: false } do
        expect(user).to be_active

        expect { subject }.not_to change(user, :attributes)
      end
    end

    context "with empty attributes" do
      let(:attributes) { {} }

      it "locks the user when enabled", with_config: { ldap_users_sync_status: true } do
        expect(user).to be_active

        subject

        expect(user.reload).to be_locked
      end

      it "does nothing when not enabled", with_config: { ldap_users_sync_status: false } do
        expect(user).to be_active

        expect { subject }.not_to change(user, :attributes)
      end
    end
  end

  context "with a new user" do
    let!(:user) { build(:user, firstname: "Bob", lastname: "Bobbit", mail: "b@example.com", login: "aa729") }

    it "creates the user" do
      expect(user.firstname).to eq "Bob"
      expect(user.lastname).to eq "Bobbit"
      expect(user.mail).to eq "b@example.com"
      expect(user).to be_new_record

      expect(subject).to be_success
      expect(subject.result).to be_a User
      expect(subject.result).to be_valid
      expect(subject.result.firstname).to eq "Alexandra"
      expect(subject.result.lastname).to eq "Adams"
      expect(subject.result.mail).to eq "a.adam@example.com"
      expect(subject.result).to be_persisted
    end

    context "with a required user custom field" do
      let!(:custom_field) { create(:user_custom_field, :string, name: "Employee ID", is_required: true) }

      it "still creates the user, as LDAP cannot provide a value for the custom field" do
        expect(subject).to be_success
        expect(subject.result).to be_persisted
      end

      it "leaves the custom field empty" do
        subject

        expect(User.find_by(login: "aa729").custom_value_for(custom_field).value).to be_nil
      end
    end
  end
end
