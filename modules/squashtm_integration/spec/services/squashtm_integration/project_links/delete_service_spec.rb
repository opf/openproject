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

RSpec.describe SquashTMIntegration::ProjectLinks::DeleteService do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  let(:permissions) { %i[manage_squashtm_integration manage_squashtm_links] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  let!(:project_link) { create(:squashtm_project_link, project:) }
  let!(:work_package_link) { create(:squashtm_work_package_link, work_package: create(:work_package, project:)) }
  let!(:other_project_work_package_link) { create(:squashtm_work_package_link, work_package: create(:work_package)) }

  subject(:result) { described_class.new(user:, model: project_link).call(params) }

  context "without removing the work package links" do
    let(:params) { {} }

    it "fails and keeps the project and work package links" do
      expect(result).not_to be_success
      expect(result.errors.details[:base]).to eq([{ error: :work_packages_linked, count: 1 }])
      expect(SquashTMIntegration::ProjectLink).to exist(project_link.id)
      expect(SquashTMIntegration::WorkPackageLink).to exist(work_package_link.id)
    end
  end

  context "when removing the work package links" do
    let(:params) { { unlink_work_packages: true } }

    it "unlinks the project and its work packages but leaves other projects alone" do
      expect(result).to be_success
      expect(SquashTMIntegration::ProjectLink).not_to exist(project_link.id)
      expect(SquashTMIntegration::WorkPackageLink).not_to exist(work_package_link.id)
      expect(SquashTMIntegration::WorkPackageLink).to exist(other_project_work_package_link.id)
    end

    it "refuses to remove them for a user who cannot manage requirement links" do
      permissions.delete(:manage_squashtm_links)

      expect(result).not_to be_success
      expect(result.errors.details[:base].pluck(:error)).to eq([:work_package_links_not_removable])
      expect(SquashTMIntegration::ProjectLink).to exist(project_link.id)
      expect(SquashTMIntegration::WorkPackageLink).to exist(work_package_link.id)
    end

    it "keeps the work package links when the project link cannot be deleted" do
      allow(project_link).to receive(:destroy).and_return(false)

      expect(result).not_to be_success
      expect(SquashTMIntegration::WorkPackageLink).to exist(work_package_link.id)
    end
  end
end
