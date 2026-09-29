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

RSpec.describe Queries::Users::Selects::MemberOfGroup do
  shared_let(:user) { create(:user) }
  shared_let(:group) { create(:group, members: [user]) }
  shared_let(:department) { create(:department, members: [user]) }

  let(:query) { UserQuery.new(name: "Users").tap { it.select(:member_of_group) } }

  current_user { create(:admin) }

  describe ".key" do
    it "is :member_of_group" do
      expect(described_class.key).to eq(:member_of_group)
    end
  end

  describe "#caption" do
    it "is the member of group label" do
      expect(described_class.new(:member_of_group).caption).to eq(I18n.t(:label_member_of_group))
    end
  end

  it "eager loads the group memberships without the departments" do
    result = query.results.to_a.detect { it == user }

    expect(result.association(:regular_groups)).to be_loaded
    expect(result.regular_groups).to contain_exactly(group)
  end
end
