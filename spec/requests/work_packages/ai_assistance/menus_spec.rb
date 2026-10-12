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

require "rails_helper"

RSpec.describe "AI Assistance menu", type: :rails_request, with_flag: { ai_assistance: true } do
  shared_let(:project) { create(:project) }
  shared_let(:assistant) { create(:ai_assistant, name: "QA assistance") }
  shared_let(:skill) { create(:ai_assistant_skill, assistant:) }

  let(:permissions) { %i[view_work_packages use_ai_assistance] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:) }

  current_user { user }

  describe "GET show" do
    it "renders the menu button in the frame" do
      get "/work_packages/#{work_package.id}/ai_assistance/menu"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-frame id="wp-ai-assistance-menu">')
      expect(response.body).to include("AI Assistance")
    end

    context "without the permission" do
      let(:permissions) { %i[view_work_packages] }

      it "renders an empty frame" do
        get "/work_packages/#{work_package.id}/ai_assistance/menu"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<turbo-frame id="wp-ai-assistance-menu">')
        expect(response.body).not_to include("AI Assistance")
      end
    end

    context "when no assistant is active" do
      before { assistant.update!(active: false) }

      after { assistant.update!(active: true) }

      it "renders an empty frame" do
        get "/work_packages/#{work_package.id}/ai_assistance/menu"

        expect(response.body).not_to include("AI Assistance")
      end
    end
  end

  describe "GET items" do
    it "lists each skill with its assistant as a label, and the history" do
      get "/work_packages/#{work_package.id}/ai_assistance/menu/items"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check health")
      expect(response.body).to include("QA assistance")
      expect(response.body).to include(%(name="skill_id" value="#{skill.id}"))
      expect(response.body).to include("History")
    end
  end
end
