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

RSpec.describe WorkPackages::ProjectAttributesTabController do
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  let(:role_with_both_permissions) do
    create(:project_role, permissions: %i[view_work_packages view_project_attributes])
  end
  let(:role_without_project_attributes) do
    create(:project_role, permissions: %i[view_work_packages])
  end

  before do
    allow(User).to receive(:current).and_return(user)
    work_package
  end

  describe "#index" do
    subject do
      get :index, params: { id: work_package.id }
      response
    end

    context "when the user has view_work_packages and view_project_attributes" do
      let(:user) { create(:user, member_with_roles: { project => role_with_both_permissions }) }

      it { is_expected.to be_successful }
    end

    context "when the user has view_work_packages but not view_project_attributes" do
      let(:user) { create(:user, member_with_roles: { project => role_without_project_attributes }) }

      it { is_expected.to be_forbidden }
    end

    context "when the user has no access to the project" do
      let(:user) { create(:user) }

      it { is_expected.to be_not_found }
    end
  end
end
