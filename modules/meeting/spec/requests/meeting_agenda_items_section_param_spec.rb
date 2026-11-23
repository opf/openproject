# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Meeting agenda item form section parameter",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] })
  end

  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:own_section) { create(:meeting_section, meeting:, title: "Own section title") }
  shared_let(:other_meeting) { create(:meeting, project: other_project) }
  shared_let(:other_section) { create(:meeting_section, meeting: other_meeting, title: "Other section title") }

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    login_as user
  end

  shared_examples "renders only sections of the meeting" do
    it "renders the section of the meeting" do
      get path, params: { meeting_section_id: own_section.id }, headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Own section title")
    end

    it "renders the backlog of the meeting" do
      get path, params: { meeting_section_id: meeting.backlog.id }, headers: turbo_headers

      expect(response).to have_http_status(:ok)
    end

    it "does not render a section of another meeting" do
      get path, params: { meeting_section_id: other_section.id }, headers: turbo_headers

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Other section title")
    end

    it "responds the same way for a section that does not exist" do
      get path, params: { meeting_section_id: 0 }, headers: turbo_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "new" do
    let(:path) { new_project_meeting_agenda_item_path(project, meeting) }

    it_behaves_like "renders only sections of the meeting"
  end

  describe "cancel_new" do
    let(:path) { cancel_new_project_meeting_agenda_items_path(project, meeting) }

    it_behaves_like "renders only sections of the meeting"
  end
end
