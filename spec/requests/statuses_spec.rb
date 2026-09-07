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

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template("new")
        expect(response.body).to include("% Complete must be between 0 and 100.")
      end
    end
  end

  describe "GET /statuses" do
    context "with more statuses than fit a page", with_settings: { per_page_options: "2, 100" } do
      shared_let(:statuses) { create_list(:status, 3) }

      it "paginates" do
        get statuses_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(statuses.first.name)
        expect(response.body).not_to include(statuses.last.name)
      end

      it "serves the requested page" do
        get statuses_path(page: 2)

        expect(response.body).to include(statuses.last.name)
        expect(response.body).not_to include(statuses.first.name)
      end

      it "keeps the whole list on one page when asked for a larger page size" do
        get statuses_path(per_page: 100)

        expect(response.body).to include(*statuses.map(&:name))
      end
    end
  end

  describe "PUT /statuses/:id/move" do
    shared_let(:first) { create(:status, name: "First") }
    shared_let(:second) { create(:status, name: "Second") }
    shared_let(:third) { create(:status, name: "Third") }

    it "moves the status to the requested relative position" do
      put move_status_path(first), params: { move_to: "lowest" }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(Status.order(:position).pluck(:name)).to eq(%w[Second Third First])
    end

    it "moves the status to an absolute position" do
      put move_status_path(third), params: { position: 1 }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(Status.order(:position).pluck(:name)).to eq(%w[Third First Second])
    end
  end
end
