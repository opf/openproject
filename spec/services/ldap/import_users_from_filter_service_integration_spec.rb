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

RSpec.describe Ldap::ImportUsersFromFilterService do
  include_context "with temporary LDAP"

  subject do
    described_class.new(ldap_auth_source, filter).call
  end

  let(:filter) { Net::LDAP::Filter.from_rfc2254 "(uid=aa729)" }

  it "adds only the matching user" do
    subject

    user_aa729 = User.find_by(login: "aa729")
    expect(user_aa729).to be_present
    expect(user_aa729.firstname).to eq "Alexandra"
    expect(user_aa729.lastname).to eq "Adams"

    user_bb459 = User.find_by(login: "bb459")
    expect(user_bb459).not_to be_present

    user_cc414 = User.find_by(login: "cc414")
    expect(user_cc414).not_to be_present
  end
end
