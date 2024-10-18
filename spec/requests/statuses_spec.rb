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

RSpec.describe "Statuses", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "POST /statuses" do
    it "creates a new status" do
      post statuses_path, params: { status: { name: "New Status" } }

      expect(Status.find_by(name: "New Status")).not_to be_nil
      expect(response).to redirect_to(statuses_path)
    end

    context "with empty % Complete" do
      it "displays an error" do
        post statuses_path, params: { status: { name: "New status", default_done_ratio: "" } }

        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
        expect(response.body).to include("% Complete must be between 0 and 100.")
      end
    end
  end
end
