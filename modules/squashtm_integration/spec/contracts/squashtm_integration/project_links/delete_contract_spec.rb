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

require "spec_helper"

RSpec.describe SquashTMIntegration::ProjectLinks::DeleteContract do
  let(:project) { build_stubbed(:project) }
  let(:link) { build_stubbed(:squashtm_project_link, project:) }
  let(:user) { build_stubbed(:user) }
  let(:permissions) { %i[manage_squashtm_integration] }

  subject(:contract) { described_class.new(link, user) }

  before do
    mock_permissions_for(user) { |mock| mock.allow_in_project(*permissions, project:) }
  end

  it "is valid for a user who can manage the SquashTM integration" do
    expect(contract).to be_valid
  end

  context "without that permission" do
    let(:permissions) { %i[view_squashtm_test_results] }

    it "is invalid" do
      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to eq([:error_unauthorized])
    end
  end
end
