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

  context "when work packages of the project are linked to SquashTM requirements" do
    let(:project) { create(:project) }
    let(:link) { create(:squashtm_project_link, project:) }

    before do
      create_list(:work_package, 2, project:).each { create(:squashtm_work_package_link, work_package: it) }
    end

    it "is invalid and reports how many work packages are linked" do
      expect(contract).not_to be_valid
      expect(contract.errors.details[:base]).to eq([{ error: :work_packages_linked, count: 2 }])
    end

    context "when the work package links are to be removed as well" do
      subject(:contract) { described_class.new(link, user, options: { unlink_work_packages: true }) }

      context "with the permission to manage requirement links" do
        let(:permissions) { %i[manage_squashtm_integration manage_squashtm_links] }

        it { is_expected.to be_valid }
      end

      context "without the permission to manage requirement links" do
        it "is invalid" do
          expect(contract).not_to be_valid
          expect(contract.errors.details[:base].pluck(:error)).to eq([:work_package_links_not_removable])
        end
      end
    end
  end

  context "when only work packages of other projects are linked" do
    let(:project) { create(:project) }
    let(:link) { create(:squashtm_project_link, project:) }

    before { create(:squashtm_work_package_link, work_package: create(:work_package)) }

    it { is_expected.to be_valid }
  end
end
