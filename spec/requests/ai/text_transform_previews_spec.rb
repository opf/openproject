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

RSpec.describe "AI text transform preview", :skip_csrf, type: :rails_request do
  context "when logged in" do
    current_user { create(:user) }

    it "renders markdown as sanitized html" do
      post ai_text_transform_preview_path, params: { markdown: "# Title\n\n**bold** <script>alert(1)</script>" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<strong>bold</strong>")
      expect(response.body).to include("Title")
      expect(response.body).not_to include("<script>")
    end

    it "renders nothing for empty markdown" do
      post ai_text_transform_preview_path, params: { markdown: "" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_blank
    end
  end

  context "when anonymous" do
    it "does not render" do
      post ai_text_transform_preview_path, params: { markdown: "**bold**" }, as: :json

      expect(response.body).not_to include("<strong>")
    end
  end
end
