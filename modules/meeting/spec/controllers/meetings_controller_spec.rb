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

require "#{File.dirname(__FILE__)}/../spec_helper"

RSpec.describe MeetingsController do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  current_user { user }

  describe "GET" do
    describe "index" do
      let(:meetings) do
        [
          create(:meeting, project:),
          create(:meeting, author: user, project:),
          create(:meeting, author: user, project: other_project)
        ]
      end

      describe "html" do
        context "when requesting meetings globally" do
          before do
            get "index"
          end

          it { expect(response).to be_successful }
          it { expect(assigns(:meetings)).to match_array meetings[1..2] }
        end

        context "when requesting meetings scoped to a project ID" do
          before do
            get "index", params: { project_id: project.id }
          end

          it { expect(response).to be_successful }
          it { expect(assigns(:meetings)).to match_array meetings[1] }
        end
      end
    end

    describe "show" do
      let(:meeting) { create(:meeting, project:, agenda: nil) }

      describe "html" do
        before do
          get "show", params: { id: meeting.id }
        end

        it { expect(response).to be_successful }
        it { expect(assigns(:meeting)).to eql meeting }
      end
    end

    describe "new" do
      let(:meeting) { Meeting.new(project:) }

      before do
        allow(Project).to receive(:find).and_return(project)
        allow(Meeting).to receive(:new).and_return(meeting)
      end

      shared_examples_for "new action" do |response_type:|
        describe response_type do
          context "when requesting the page without a project id" do
            before do
              get "new"
            end

            it { expect(response).to be_successful }
            it { expect(assigns(:meeting)).to eql meeting }
            it { expect(assigns(:project)).to be_nil }
          end

          context "when requesting the page with a project id" do
            before do
              get "new", params: { project_id: project.id }
            end

            it { expect(response).to be_successful }
            it { expect(assigns(:meeting)).to eql meeting }
            it { expect(assigns(:project)).to eql project }
          end
        end
      end

      it_behaves_like "new action", response_type: "html"
      it_behaves_like "new action", response_type: "turbo_stream"
    end

    describe "edit" do
      let(:meeting) { create(:meeting, project:) }

      describe "html" do
        before do
          get "edit", params: { id: meeting.id }
        end

        it { expect(response).to be_successful }
        it { expect(assigns(:meeting)).to eql meeting }
      end
    end
  end

  describe "POST" do
    describe "create" do
      render_views

      let(:base_params) do
        {
          project_id: project&.id,
          meeting: meeting_params
        }
      end

      let(:base_meeting_params) do
        {
          title: "Foobar",
          duration: "1.0",
          start_date: "2015-06-01",
          start_time_hour: "10:00"
        }
      end

      let(:params) { base_params }
      let(:meeting_params) { base_meeting_params }

      before do
        post :create,
             params:
      end

      context "with a project_id" do
        context "and an invalid start_date with start_time_hour" do
          let(:meeting_params) do
            base_meeting_params.merge(start_date: "-")
          end

          it "renders an error" do
            expect(response).to have_http_status :ok
            expect(response).to render_template :new
            expect(response.body)
              .to have_css "#errorExplanation li",
                           text: "Date #{I18n.t('activerecord.errors.messages.not_an_iso_date')}"
          end
        end

        context "and an invalid start_time_hour with start_date" do
          let(:meeting_params) do
            base_meeting_params.merge(start_time_hour: "-")
          end

          it "renders an error" do
            expect(response).to have_http_status :ok
            expect(response).to render_template :new
            expect(response.body)
              .to have_css "#errorExplanation li",
                           text: "Start time #{I18n.t('activerecord.errors.messages.invalid_time_format')}"
          end
        end
      end

      context "with a nil project_id" do
        let(:project) { nil }

        it "renders an error" do
          expect(response).to have_http_status :ok
          expect(response).to render_template :new
          expect(response.body)
            .to have_css "#errorExplanation li",
                         text: "Project #{I18n.t('activerecord.errors.messages.blank')}"
        end
      end

      context "without a project_id" do
        let(:params) { base_params.except(:project_id) }
        let(:project) { nil }

        it "renders an error" do
          expect(response).to have_http_status :ok
          expect(response).to render_template :new
          expect(response.body)
            .to have_css "#errorExplanation li",
                         text: "Project #{I18n.t('activerecord.errors.messages.blank')}"
        end
      end
    end
  end

  describe "notify" do
    let!(:meeting) { create(:meeting) }
    let!(:participant) { create(:meeting_participant, meeting:, attended: true) }

    it "produces a background job for notification" do
      post :notify, params: { id: meeting.id }

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    context "with an error during deliver" do
      before do
        allow(MeetingMailer).to receive(:invited).and_raise(Net::SMTPError)
      end

      it "produces a flash message containing the mail addresses raising the error" do
        expect { post :notify, params: { id: meeting.id } }.not_to raise_error
        meeting.participants.each do |participant|
          expect(flash[:error]).to include(participant.name)
        end

        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end
  end
end
