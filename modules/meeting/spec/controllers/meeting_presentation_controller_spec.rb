# frozen_string_literal: true

# -- copyright
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
# ++
require "spec_helper"

RSpec.describe MeetingPresentationController do
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:project) { create(:project, enabled_module_names: ["meetings"]) }
  let(:permissions) { [:view_meetings] }

  let(:meeting) { create(:meeting, project:) }
  let!(:agenda_item) { create(:meeting_agenda_item, meeting:) }

  before do
    login_as(user)
  end

  describe "POST #start" do
    subject { post :start, params: { project_id: project.id, meeting_id: meeting.id } }

    context "when the meeting does not have any agenda items" do
      before do
        meeting.agenda_items.destroy_all
      end

      it "redirects to the meeting page" do
        subject
        expect(response).to redirect_to(project_meeting_path(project, meeting))
        expect(flash[:warning]).to eq(I18n.t("meeting.presentation_mode.no_items_flash"))
      end
    end

    context "when the user is allowed to edit meetings" do
      let(:permissions) { %i[view_meetings edit_meetings] }

      it "moves the meeting to in_progress and redirects to show" do
        expect do
          subject
          meeting.reload
        end.to change(meeting, :state).from("open").to("in_progress")

        expect(response).to redirect_to(project_meeting_presentation_path(project.id, meeting))
      end
    end

    context "when the user is not allowed to edit meetings" do
      it "does not change the state of the meeting and redirects to show" do
        expect do
          subject
          meeting.reload
        end.not_to change(meeting, :state)

        expect(response).to redirect_to(project_meeting_presentation_path(project.id, meeting))
      end
    end
  end

  describe "GET #show" do
    let!(:agenda_item) { create(:meeting_agenda_item, meeting:, notes: "One\n\n---\n\nTwo\n\n---\n\nThree") }
    let!(:second_item) { create(:meeting_agenda_item, meeting:, notes: "Four\n\n---\n\nFive") }

    let(:navigation_params) { {} }

    before do
      get :show, params: { project_id: project.id, meeting_id: meeting.id, **navigation_params }
    end

    shared_examples "presents" do |item:, slide:|
      it "presents slide #{slide} of the #{item}" do
        expect(response).to have_http_status(:ok)
        expect(assigns(:current_id)).to eq(send(item).id)
        expect(assigns(:current_slide)).to eq(slide)
      end
    end

    context "without a position" do
      it "starts at the first slide" do
        expect(assigns(:current_id)).to be_nil
        expect(assigns(:current_slide)).to eq(1)
      end
    end

    context "when moving to the next slide within an item" do
      let(:navigation_params) { { current_id: agenda_item.id, slide: 1, action_type: "next" } }

      it_behaves_like "presents", item: :agenda_item, slide: 2
    end

    context "when moving next from the last slide of an item" do
      let(:navigation_params) { { current_id: agenda_item.id, slide: 3, action_type: "next" } }

      it_behaves_like "presents", item: :second_item, slide: 1
    end

    context "when moving next from the last slide of the last item" do
      let(:navigation_params) { { current_id: second_item.id, slide: 2, action_type: "next" } }

      it_behaves_like "presents", item: :second_item, slide: 2
    end

    context "when moving to the previous slide within an item" do
      let(:navigation_params) { { current_id: second_item.id, slide: 2, action_type: "previous" } }

      it_behaves_like "presents", item: :second_item, slide: 1
    end

    context "when moving previous from the first slide of an item" do
      let(:navigation_params) { { current_id: second_item.id, slide: 1, action_type: "previous" } }

      it_behaves_like "presents", item: :agenda_item, slide: 3
    end

    context "when moving previous from the first slide of the first item" do
      let(:navigation_params) { { current_id: agenda_item.id, slide: 1, action_type: "previous" } }

      it_behaves_like "presents", item: :agenda_item, slide: 1
    end

    context "when the slide is beyond the item's slides" do
      context "and moving next" do
        let(:navigation_params) { { current_id: agenda_item.id, slide: 9, action_type: "next" } }

        it_behaves_like "presents", item: :second_item, slide: 1
      end

      context "and moving previous" do
        let(:navigation_params) { { current_id: agenda_item.id, slide: 9, action_type: "previous" } }

        it_behaves_like "presents", item: :agenda_item, slide: 2
      end
    end
  end
end
