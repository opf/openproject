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
require_module_spec_helper

RSpec.describe "My AI assistants", :skip_csrf, type: :rails_request, with_flag: { ai_assistance: true } do
  let(:user) { create(:user, global_permissions: %i[manage_own_ai_assistants]) }
  let(:other_user) { create(:user, global_permissions: %i[manage_own_ai_assistants]) }
  let!(:own_assistant) { create(:ai_assistant, name: "My helper", principal: user) }
  let!(:other_assistant) { create(:ai_assistant, name: "Their helper", principal: other_user) }
  let!(:global_assistant) { create(:ai_assistant, name: "QA assistance") }

  current_user { user }

  describe "GET /my/ai_assistants" do
    it "lists only the user's own assistants" do
      get my_ai_assistants_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My helper")
      expect(response.body).not_to include("Their helper")
      expect(response.body).not_to include("QA assistance")
    end

    context "without the permission" do
      let(:user) { create(:user) }

      it "is forbidden" do
        get my_ai_assistants_path

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with the feature flag off", with_flag: { ai_assistance: false } do
      it "responds with not found" do
        get my_ai_assistants_path

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /my/ai_assistants/new" do
    it "renders the form without a model select" do
      get new_my_ai_assistant_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ai_assistant[name]")
      expect(response.body).not_to include("ai_assistant[model_id]")
    end
  end

  describe "POST /my/ai_assistants" do
    it "creates a personal assistant and ignores a model" do
      post my_ai_assistants_path, params: { ai_assistant: { name: "Reviewer", model_id: "expensive", active: "1" } }

      assistant = AI::Assistant.find_by!(name: "Reviewer")
      expect(assistant).to have_attributes(principal: user, model_id: nil)
      expect(response).to redirect_to(edit_my_ai_assistant_path(assistant))
    end
  end

  describe "the assistant of another user" do
    it "is not found on edit, update and delete" do
      get edit_my_ai_assistant_path(other_assistant)
      expect(response).to have_http_status(:not_found)

      patch my_ai_assistant_path(other_assistant), params: { ai_assistant: { name: "Taken" } }
      expect(response).to have_http_status(:not_found)

      delete my_ai_assistant_path(global_assistant)
      expect(response).to have_http_status(:not_found)

      expect(other_assistant.reload.name).to eq("Their helper")
      expect(AI::Assistant.exists?(global_assistant.id)).to be(true)
    end

    it "cannot get a skill added" do
      post my_ai_assistant_skills_path(other_assistant),
           params: { ai_assistant_skill: { prompt: "Hi" } }

      expect(response).to have_http_status(:not_found)
      expect(other_assistant.skills.count).to eq(0)
    end
  end

  describe "POST /my/ai_assistants/:id/skills" do
    it "creates a skill" do
      post my_ai_assistant_skills_path(own_assistant),
           params: { ai_assistant_skill: { prompt: "Summarize it." } }

      skill = own_assistant.skills.sole
      expect(skill).to have_attributes(skill_key: "conversation", variant: "preset", prompt: "Summarize it.")
      expect(response).to redirect_to(edit_my_ai_assistant_path(own_assistant))
    end
  end

  describe "POST /my/ai_assistants/:id/copy" do
    it "copies the user's own assistant for the user" do
      post copy_my_ai_assistant_path(own_assistant)

      copy = AI::Assistant.find_by!(name: "My helper (copy)")
      expect(copy.principal).to eq(user)
      expect(response).to redirect_to(edit_my_ai_assistant_path(copy))
    end

    it "does not copy the assistant of another user" do
      post copy_my_ai_assistant_path(other_assistant)

      expect(response).to have_http_status(:not_found)
      expect(AI::Assistant.where(name: "Their helper (copy)")).not_to exist
    end
  end
end
