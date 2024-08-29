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

RSpec.describe WorkPackages::CreateContract do
  let(:work_package) { build(:work_package, author: other_user, project:) }
  let(:other_user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:permissions) do
    %i[
      view_work_packages
      add_work_packages
    ]
  end
  let(:changed_values) { [] }

  let(:user) { build_stubbed(:user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project *permissions, project:
    end

    allow(work_package).to receive(:changed).and_return(changed_values)
  end

  subject(:contract) { described_class.new(work_package, user) }

  describe "story points" do
    before do
      contract.validate
    end

    context "when not changed" do
      it("is valid") { expect(contract.errors.symbols_for(:story_points)).to be_empty }
    end

    context "when changed" do
      let(:changed_values) { ["story_points"] }

      it("is valid") { expect(contract.errors.symbols_for(:story_points)).to be_empty }
    end
  end
end
