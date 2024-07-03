# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe SharesController do
  shared_let(:user) { create(:user) }

  before { login_as(user) }

  describe "entity specific behavior" do
    context "for a work package" do
      let(:work_package) { create(:work_package) }
      let(:make_request) do
        get :index, params: { work_package_id: work_package.id }
      end

      context "when the user does not have permission to access the work package" do
        before do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end
        end

        it "raises a RecordNotFound error" do
          expect { make_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the user does have permission" do
        before do
          role = create(:project_role, permissions: %i[view_work_packages view_shared_work_packages])
          create(:member, project: work_package.project, principal: user, roles: [role])
          make_request
        end

        it "loads the work package" do
          expect(assigns(:entity)).to eq(work_package)
        end
      end
    end

    context "for a project query" do
    end
  end

  describe "dialog" do
  end

  describe "index" do
  end

  describe "create" do
  end

  describe "update" do
  end

  describe "destroy" do
  end

  describe "resend_invite" do
  end

  describe "bulk_update" do
  end

  describe "bulk_destroy" do
  end
end
