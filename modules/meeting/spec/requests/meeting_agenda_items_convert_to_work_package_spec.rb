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

RSpec.describe "Convert agenda item to work package permissions",
               :skip_csrf,
               type: :rails_request do
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:type) { create(:type_task) }
  shared_let(:project) do
    create(:project, types: [type], enabled_module_names: %w[meetings work_package_tracking])
  end
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }

  let(:dialog_path) do
    convert_to_work_package_dialog_project_meeting_agenda_item_path(project, meeting, meeting_agenda_item)
  end
  let(:refresh_path) do
    refresh_convert_to_work_package_dialog_project_meeting_agenda_item_path(project, meeting, meeting_agenda_item)
  end
  let(:convert_path) do
    convert_to_work_package_project_meeting_agenda_item_path(project, meeting, meeting_agenda_item)
  end
  let(:wp_params) do
    { work_package: { type_id: type.id, subject: "Converted item" } }
  end

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before { login_as(user) }

  shared_examples "forbids all convert routes" do
    it "denies GET to the dialog" do
      get dialog_path, headers: turbo_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "denies POST to refresh" do
      post refresh_path, params: wp_params, headers: turbo_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "denies POST to convert and does not create a work package" do
      expect { post convert_path, params: wp_params, headers: turbo_headers }
        .not_to change(WorkPackage, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with both :manage_agendas and :add_work_packages" do
    let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_meetings manage_agendas add_work_packages view_work_packages]
             })
    end

    it "allows GET to the dialog" do
      get dialog_path, headers: turbo_headers
      expect(response).to have_http_status(:ok)
    end

    it "allows POST to refresh" do
      post refresh_path, params: wp_params, headers: turbo_headers
      expect(response).to have_http_status(:ok)
    end

    it "allows POST to convert and creates a work package" do
      expect { post convert_path, params: wp_params, headers: turbo_headers }
        .to change(WorkPackage, :count).by(1)
      expect(response).to have_http_status(:ok)

      meeting_agenda_item.reload
      expect(meeting_agenda_item).to be_work_package
    end
  end

  context "with :manage_agendas but missing :add_work_packages" do
    let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_meetings manage_agendas view_work_packages]
             })
    end

    include_examples "forbids all convert routes"
  end

  context "with :add_work_packages but missing :manage_agendas" do
    let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_meetings add_work_packages view_work_packages]
             })
    end

    include_examples "forbids all convert routes"
  end

  context "without any project permissions" do
    let(:user) { create(:user) }

    include_examples "forbids all convert routes"
  end
end
