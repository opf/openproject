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

RSpec.describe "Admin AI assistants", :skip_csrf, type: :rails_request, with_flag: { ai_assistance: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:owner) { create(:user, firstname: "Ada", lastname: "Owner") }
  shared_let(:global_assistant) { create(:ai_assistant, name: "QA assistance") }
  shared_let(:personal_assistant) { create(:ai_assistant, name: "My helper", user: owner) }

  current_user { admin }

  describe "GET /admin/ai_assistants" do
    it "lists global and personal assistants with their owner" do
      get admin_ai_assistants_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("QA assistance", "My helper", "Ada Owner")
    end

    it "filters by owner" do
      get admin_ai_assistants_path(owner: "personal")

      expect(response.body).to include("My helper")
      expect(response.body).not_to include("QA assistance")

      get admin_ai_assistants_path(owner: "global")

      expect(response.body).to include("QA assistance")
      expect(response.body).not_to include("My helper")
    end
  end

  describe "a personal assistant" do
    it "can be edited with a model, and keeps its owner" do
      get edit_admin_ai_assistant_path(personal_assistant)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("personal assistant of Ada Owner", "ai_assistant[model_id]")

      patch admin_ai_assistant_path(personal_assistant),
            params: { ai_assistant: { name: "Renamed", model_id: "test-model", active: "0" } }

      expect(personal_assistant.reload).to have_attributes(name: "Renamed", model_id: "test-model",
                                                           active: false, user: owner)
    end
  end

  describe "POST /admin/ai_assistants" do
    it "creates a global assistant" do
      post admin_ai_assistants_path, params: { ai_assistant: { name: "Release helper" } }

      expect(AI::Assistant.find_by!(name: "Release helper").user).to be_nil
    end
  end
end
