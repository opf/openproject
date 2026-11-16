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

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::SynchronizedTree do
  let(:ldap_auth_source) { create(:ldap_auth_source, base_dn: "dc=example,dc=com") }

  subject { build(:ldap_synchronized_tree, ldap_auth_source:, base_dn:) }

  context "with a base DN inside the auth source base" do
    let(:base_dn) { "ou=IT,dc=example,dc=com" }

    it { is_expected.to be_valid }
  end

  context "with a base DN equal to the auth source base" do
    let(:base_dn) { "dc=example,dc=com" }

    it { is_expected.to be_valid }
  end

  context "with a base DN outside the auth source base" do
    let(:base_dn) { "ou=IT,dc=other,dc=com" }

    it "is invalid" do
      expect(subject).not_to be_valid
      expect(subject.errors[:base_dn]).to be_present
    end
  end

  context "with an invalid structure filter" do
    let(:base_dn) { "dc=example,dc=com" }

    it "is invalid" do
      subject.structure_filter_string = "(objectClass="
      expect(subject).not_to be_valid
      expect(subject.errors[:structure_filter_string]).to be_present
    end
  end

  describe "overlap with sibling trees" do
    let(:base_dn) { "ou=IT,dc=example,dc=com" }

    before { create(:ldap_synchronized_tree, ldap_auth_source:, base_dn: "ou=IT,dc=example,dc=com") }

    it "rejects an identical base" do
      expect(subject).not_to be_valid
      expect(subject.errors[:base_dn]).to be_present
    end

    it "rejects a descendant base" do
      subject.base_dn = "ou=Development,ou=IT,dc=example,dc=com"
      expect(subject).not_to be_valid
    end

    it "allows a disjoint base" do
      subject.base_dn = "ou=HR,dc=example,dc=com"
      expect(subject).to be_valid
    end
  end
end
