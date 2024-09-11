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

RSpec.describe Queries::Members::Filters::PrincipalFilter do
  let(:user) { build_stubbed(:user) }
  let(:group) { build_stubbed(:group) }
  let(:current_user) { build_stubbed(:user) }

  before do
    login_as(current_user)
    principal_scope = double("principal scope")

    allow(Principal)
      .to receive(:not_locked)
      .and_return(principal_scope)

    allow(principal_scope)
      .to receive(:visible)
      .and_return([user, group, current_user])
  end

  it_behaves_like "basic query filter" do
    let(:class_key) { :principal_id }
    let(:type) { :list_optional }
    let(:name) { Member.human_attribute_name(:principal) }

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expected = [[user.name, user.id.to_s],
                    [group.name, group.id.to_s],
                    [current_user.name, current_user.id.to_s],
                    %w(me me)]

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end

  it_behaves_like "list_optional query filter" do
    let(:attribute) { :user_id }
    let(:model) { Member }
    let(:valid_values) { [user.id.to_s, group.id.to_s, current_user.id.to_s] }
  end
end
