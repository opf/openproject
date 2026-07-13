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

RSpec.describe "Work package priorities",
               :aggregate_failures,
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:priority) { create(:issue_priority, name: "High") }
  shared_let(:other_priority) { create(:issue_priority, name: "Other") }

  before do
    login_as(admin)
  end

  describe "GET /admin/settings/work_package_priorities" do
    it "renders the index template" do
      get admin_settings_work_package_priorities_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include "High"
      expect(response.body).to include "Other"
    end
  end

  describe "DELETE /admin/settings/work_package_priorities/:id" do
    let(:params) { {} }

    context "without work packages assigned" do
      it "redirects to the priorities index" do
        delete(admin_settings_work_package_priority_path(priority), params:)
        expect(response).to redirect_to admin_settings_work_package_priorities_path
        expect(response).to have_http_status(:see_other)
        expect { priority.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with work packages assigned" do
      shared_let(:work_package) { create(:work_package, priority:) }

      it "renders the reassign template" do
        delete(admin_settings_work_package_priority_path(priority), params:)
        expect(response).to redirect_to reassign_admin_settings_work_package_priority_path(priority)
        expect { priority.reload }.not_to raise_error
        expect(work_package.reload.priority).to eq priority
      end

      context "with work packages assigned and reassigning" do
        let(:params) do
          {
            enumeration: { reassign_to_id: other_priority.id }
          }
        end

        it "reassigns the priority" do
          delete(admin_settings_work_package_priority_path(priority), params:)
          expect(response).to redirect_to admin_settings_work_package_priorities_path
          expect { priority.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(work_package.reload.priority).to eq other_priority
        end
      end
    end
  end

  describe "PUT /admin/settings/work_package_priorities/:id/move" do
    it "moves the category to the bottom" do
      put move_admin_settings_work_package_priority_path(priority), params: { move_to: "lowest" }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(priority.reload.position).to be > other_priority.reload.position
    end
  end
end
