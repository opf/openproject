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

require "rails_helper" require_module_spec_helper

RSpec.describe "AI Assistance menu", type: :rails_request, with_flag: { ai_assistance: true } do
  include_context "with an available LLM for AI Assistance"

  shared_let(:project) { create(:project) }
  shared_let(:assistant) { create(:ai_assistant, name: "QA assistance") }
  shared_let(:skill) { create(:ai_assistant_skill, assistant:) }

  let(:permissions) { %i[view_work_packages use_ai_assistance] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:) }

  current_user { user }

  describe "GET show" do
    it "renders the menu button in the frame" do
      get "/ai_assistance/menu", params: { work_package_id: work_package.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-frame id="wp-ai-assistance-menu">')
      expect(response.body).to include("AI Assistance")
    end

    context "with a work package that the user cannot see" do
      let(:hidden_work_package) { create(:work_package) }

      it "renders an empty frame instead of an error, because the header asks for any id in the URL" do
        get "/ai_assistance/menu", params: { work_package_id: hidden_work_package.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<turbo-frame id="wp-ai-assistance-menu">')
        expect(response.body).not_to include("AI Assistance")
      end
    end

    context "without the permission" do
      let(:permissions) { %i[view_work_packages] }

      it "renders an empty frame" do
        get "/ai_assistance/menu", params: { work_package_id: work_package.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<turbo-frame id="wp-ai-assistance-menu">')
        expect(response.body).not_to include("AI Assistance")
      end
    end

    context "when no assistant is active" do
      before { assistant.update!(active: false) }

      after { assistant.update!(active: true) }

      it "renders an empty frame" do
        get "/ai_assistance/menu", params: { work_package_id: work_package.id }

        expect(response.body).not_to include("AI Assistance")
      end
    end
  end

  describe "the menu items" do
    it "lists each skill under a heading with its assistant's name, and the history" do
      get "/ai_assistance/menu", params: { work_package_id: work_package.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(skill.display_label)
      expect(response.body).to include("QA assistance")
      expect(response.body).to include(%(name="skill_id" value="#{skill.id}"))
      expect(response.body).to include("History")
    end
  end

  describe "a skill with conditions" do
    let!(:bug_skill) do
      create(:ai_assistant_skill, :preset, assistant:, label: "Reproduce the bug", prompt: "Try it.",
                                           conditions: { type_ids: [create(:type).id] })
    end

    it "is not listed on a work package that does not match" do
      get "/ai_assistance/menu", params: { work_package_id: work_package.id }

      expect(response.body).not_to include("Reproduce the bug")
    end

    it "is listed on a work package that matches" do
      bug = create(:work_package, project:, type: Type.find(bug_skill.condition_ids(:type_ids).first))

      get "/ai_assistance/menu", params: { work_package_id: bug.id }

      expect(response.body).to include("Reproduce the bug")
    end
  end

  describe "a group assistant" do
    let(:group) { create(:group) }
    let!(:group_skill) do
      create(:ai_assistant_skill, assistant: create(:ai_assistant, name: "Team helper", principal: group),
                                  prompt: "Summarize it.")
    end

    it "is listed for the members of the group" do
      GroupUser.create!(group:, user:)

      get "/ai_assistance/menu", params: { work_package_id: work_package.id }

      expect(response.body).to include("Team helper", %(value="#{group_skill.id}"))
    end

    it "is not listed for other users" do
      get "/ai_assistance/menu", params: { work_package_id: work_package.id }

      expect(response.body).not_to include("Team helper")
    end
  end

  describe "a personal assistant" do
    let(:owner) do
      create(:user, member_with_permissions: { project => permissions },
                    global_permissions: %i[manage_own_ai_assistants])
    end
    let!(:personal_skill) do
      create(:ai_assistant_skill, assistant: create(:ai_assistant, name: "My helper", principal: owner),
                                  prompt: "Summarize it.")
    end

    context "for its owner" do
      let(:user) { owner }

      it "lists personal, then group, then global assistants" do
        group = create(:group, members: [owner])
        create(:ai_assistant_skill, assistant: create(:ai_assistant, name: "Team helper", principal: group), prompt: "Go.")

        get "/ai_assistance/menu", params: { work_package_id: work_package.id }

        positions = ["My helper", "Team helper", "QA assistance"].map { |name| response.body.index(name) }
        expect(positions).to all(be_present)
        expect(positions).to eq(positions.sort)
      end
    end

    context "for another user" do
      it "does not list it" do
        get "/ai_assistance/menu", params: { work_package_id: work_package.id }

        expect(response.body).not_to include("My helper")
      end
    end

    context "when the owner lost the permission" do
      let(:owner) { create(:user, member_with_permissions: { project => permissions }) }
      let(:user) { owner }

      it "does not list it" do
        get "/ai_assistance/menu", params: { work_package_id: work_package.id }

        expect(response.body).not_to include("My helper")
      end
    end
  end

  describe "off a work package" do
    let!(:everywhere) { create(:ai_assistant_skill, :chat, assistant:, label: "Ask anything", offered_on: "everywhere") }

    it "lists only the Everywhere skills on a project page" do
      get "/ai_assistance/menu", params: { project_id: project.identifier }

      expect(response.body).to include("Ask anything", "History")
      expect(response.body).not_to include(%(value="#{skill.id}"))
    end

    it "lists them on a page without a project" do
      get "/ai_assistance/menu"

      expect(response.body).to include("Ask anything")
    end

    it "lists both kinds on a work package" do
      get "/ai_assistance/menu", params: { work_package_id: work_package.id }

      expect(response.body).to include("Ask anything", %(value="#{skill.id}"))
    end

    context "in a project without the permission" do
      let(:other_project) { create(:project) }
      let(:user) do
        create(:user, member_with_permissions: { project => permissions, other_project => %i[view_work_packages] })
      end

      it "renders an empty frame" do
        get "/ai_assistance/menu", params: { project_id: other_project.identifier }

        expect(response.body).not_to include("Ask anything")
      end
    end

    context "without the permission in any project" do
      let(:permissions) { %i[view_work_packages] }

      it "renders an empty frame on a page without a project" do
        get "/ai_assistance/menu"

        expect(response.body).not_to include("Ask anything")
      end
    end
  end
end
