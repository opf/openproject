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

RSpec.describe LdapGroups::SynchronizedFilter do
  describe "#used_base_dn" do
    let(:ldap_auth_source) { build(:ldap_auth_source, base_dn: "dc=example,dc=com") }
    let(:filter) { build(:ldap_synchronized_filter, ldap_auth_source:) }

    it "validates the end of the base dn matches the ldap_auth_source" do
      filter.base_dn = nil
      expect(filter.base_dn).to be_nil
      expect(filter.used_base_dn).to eq(ldap_auth_source.base_dn)
    end
  end

  describe "#base_dn" do
    let(:ldap_auth_source) { build(:ldap_auth_source, base_dn: "dc=example,dc=com") }
    let(:filter) { build(:ldap_synchronized_filter, ldap_auth_source:) }

    it "validates the end of the base dn matches the ldap_auth_source" do
      filter.base_dn = nil
      expect(filter).to be_valid

      filter.base_dn = "dc=something,dc=else"
      expect(filter).not_to be_valid
      expect(filter.errors.details[:base_dn]).to contain_exactly(error: :must_contain_base_dn)
    end
  end
end
