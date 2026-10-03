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

RSpec.describe "Safety fallbacks in the core patches" do # rubocop:disable RSpec/DescribeClass
  let(:story) { create(:type) }
  let(:project) { create(:project, types: [story]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] }) }

  it "passes the patch target guard against the current core" do
    expect { OpenProject::TypeSchemes.assert_patch_targets! }.not_to raise_error
  end

  it "falls back to native types when the resolver raises" do
    allow(TypeSchemes::Resolver).to receive(:allowed_types).and_raise(StandardError, "boom")
    contract = WorkPackages::CreateContract.new(build(:work_package, project:, type: story), user)

    expect(contract.assignable_types.to_a).to eq [story]
  end

  it "allows the type when the scheme check raises" do
    allow(TypeSchemes::Resolver).to receive(:type_allowed?).and_raise(StandardError, "boom")
    contract = WorkPackages::CreateContract.new(build(:work_package, project:, type: story, author: user), user)

    contract.validate
    expect(contract.errors.symbols_for(:type_id)).not_to include(:not_in_scheme)
  end

  it "reports a concurrent default switch as a validation failure instead of raising" do
    scheme = create(:type_scheme, types: [story])
    allow(scheme).to receive(:lock!).and_raise(ActiveRecord::RecordNotUnique)

    expect(TypeSchemes::SchemeService.update(scheme, name: "Other")).to be_failure
  end
end
