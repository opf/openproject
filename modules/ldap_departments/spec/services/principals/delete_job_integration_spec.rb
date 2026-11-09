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

RSpec.describe Principals::DeleteJob, "LDAP departments", type: :model do
  subject(:job) { described_class.perform_now(user) }

  shared_let(:deleted_user) { create(:deleted_user) }

  let(:department) { create(:department, lastname: "Frontend") }
  let(:synchronized_department) { create(:ldap_synchronized_department, group: department) }
  let(:user) { create(:user) }

  before do
    synchronized_department.add_members!([user])
  end

  it "can delete a user that is a synchronized department member" do
    expect(LdapDepartments::Membership.where(user:)).to exist

    expect { job }.to change(LdapDepartments::Membership, :count).by(-1)

    expect(User.exists?(user.id)).to be(false)
    expect(LdapDepartments::Membership.where(user_id: user.id)).not_to exist
  end

  it "keeps the synchronized department itself" do
    job

    expect(Group.exists?(department.id)).to be(true)
    expect(LdapDepartments::SynchronizedDepartment.exists?(synchronized_department.id)).to be(true)
  end
end
