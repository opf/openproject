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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.

require "spec_helper"

RSpec.describe "Admin AI landing", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  describe "GET /admin/ai" do
    subject { get admin_ai_path }

    current_user { admin }

    context "with the LLM connection active", with_flag: { llm_connection: true, ai_text_actions: true } do
      it "redirects to the LLM settings" do
        subject

        expect(response).to redirect_to(llm_connection_path)
      end
    end

    context "with only text actions active", with_flag: { llm_connection: false, ai_text_actions: true } do
      it "redirects to the text assistant" do
        subject

        expect(response).to redirect_to(admin_text_actions_path)
      end
    end

    context "with no flag active", with_flag: { llm_connection: false, ai_text_actions: false } do
      it "redirects to the MCP settings" do
        subject

        expect(response).to redirect_to(mcp_configurations_path)
      end
    end
  end
end
