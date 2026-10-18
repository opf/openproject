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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "AI Assistance button in the app header", type: :rails_request do
  include_context "with an available LLM for AI Assistance"

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages use_ai_assistance] }) }

  current_user { user }

  def header_button
    response.parsed_body.at_css("[data-test-selector='ai-assistance-header']")
  end

  context "with the feature flag", with_flag: { ai_assistance: true } do
    it "renders the hidden button with the menu URL, also on a page without a project" do
      get "/my/account"

      expect(header_button).to be_present
      expect(header_button["hidden"]).to be_present
      expect(header_button["data-ai-assistance--header-button-menu-url-value"]).to eq("/ai_assistance/menu")
    end

    context "without the permission in any project" do
      let(:user) { create(:user) }

      it "renders no button" do
        get "/my/account"

        expect(header_button).to be_nil
      end
    end
  end

  context "without the feature flag", with_flag: { ai_assistance: false } do
    it "renders no button" do
      get "/my/account"

      expect(header_button).to be_nil
    end
  end
end
