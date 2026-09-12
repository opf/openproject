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

    let(:drop_params) { { list_type: "status", list_id: "", prev_id: "" } }

    it "moves the status to the requested relative position" do
      put move_status_path(first), params: { move_to: "lowest" }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(Status.order(:position).pluck(:name)).to eq(%w[Second Third First])
    end

    it "moves the status to the top for a blank anchor" do
      put move_status_path(third), params: drop_params, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(Status.order(:position).pluck(:name)).to eq(%w[Third First Second])
    end

    it "moves down after an anchor" do
      put move_status_path(first), params: drop_params.merge(prev_id: third.id), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(Status.order(:position).pluck(:name)).to eq(%w[Second Third First])
    end

    it "moves up after an anchor" do
      put move_status_path(third), params: drop_params.merge(prev_id: first.id), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(Status.order(:position).pluck(:name)).to eq(%w[First Third Second])
    end

    it "morphs the existing list boundary" do
      put move_status_path(third), params: drop_params, as: :turbo_stream

      expect(response.body).to have_css('turbo-stream[action="update"][method="morph"][target="statuses-index-component"]')
    end

    {
      "missing anchor" => { list_type: "status", list_id: "" },
      "unknown anchor" => { list_type: "status", list_id: "", prev_id: "999999" },
      "wrong list type" => { list_type: "section", list_id: "", prev_id: "" },
      "missing list type" => { list_id: "", prev_id: "" },
      "nonblank list ID" => { list_type: "status", list_id: "1", prev_id: "" },
      "array anchor" => { list_type: "status", list_id: "", prev_id: [""] },
      "hash anchor" => { list_type: "status", list_id: "", prev_id: { id: "1" } },
      "array list ID" => { list_type: "status", list_id: [""], prev_id: "" },
      "hash list ID" => { list_type: "status", list_id: { id: "" }, prev_id: "" },
      "retired position" => { position: 1 },
      "empty request" => {}
    }.each do |description, request_params|
      it "refuses #{description} without changing order" do
        put move_status_path(third), params: request_params, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(I18n.t(:error_invalid_list_move_anchor))
        expect(Status.order(:position).pluck(:name)).to eq(%w[First Second Third])
      end
    end

    it "refuses a self-anchor without changing order" do
      put move_status_path(third), params: drop_params.merge(prev_id: third.id), as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Status.order(:position).pluck(:name)).to eq(%w[First Second Third])
    end

    it "refuses invalid menu directions with the menu error message" do
      put move_status_path(third), params: { move_to: "sideways" }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("statuses.index.could_not_be_moved"))
      expect(Status.order(:position).pluck(:name)).to eq(%w[First Second Third])
    end

    context "when not an admin" do
      current_user { create(:user) }

      it "forbids reordering" do
        put move_status_path(third), params: drop_params, as: :turbo_stream

        expect(response).to have_http_status(:forbidden)
        expect(Status.order(:position).pluck(:name)).to eq(%w[First Second Third])
      end
    end

    context "when the list is paginated", with_settings: { per_page_options: "2, 100" } do
      before { Status.delete_all }

      let!(:a) { create(:status, name: "A") }
      let!(:b) { create(:status, name: "B") }
      let!(:c) { create(:status, name: "C") }
      let!(:d) { create(:status, name: "D") }
      let!(:e) { create(:status, name: "E") }

      it "resolves a blank anchor against the start of the requested page" do
        put move_status_path(d, page: 2, per_page: 2),
            params: drop_params,
            as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(Status.order(:position).pluck(:name)).to eq(%w[A B D C E])
      end

      it "uses the global anchor for a downward move on a later page" do
        put move_status_path(c, page: 2, per_page: 2),
            params: drop_params.merge(prev_id: d.id),
            as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(Status.order(:position).pluck(:name)).to eq(%w[A B D C E])
      end

      it "ignores filters when resolving and rendering a move" do
        task = create(:type)

        put move_status_path(d, page: 2, per_page: 2),
            params: drop_params.merge(filters: [{ type: { operator: "=", values: [task.id.to_s] } }].to_json),
            as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(Status.order(:position).pluck(:name)).to eq(%w[A B D C E])
        expect(response.body).to include("status-row-#{c.id}", "status-row-#{d.id}")
        expect(response.body).not_to include("status-row-#{a.id}", "status-row-#{e.id}")
      end

      it "refuses an empty page even if its preceding neighbour exists" do
        e.destroy!

        put move_status_path(c, page: 3, per_page: 2), params: drop_params, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Status.order(:position).pluck(:name)).to eq(%w[A B C D])
      end

      it "refuses a page-start anchor that has become the moved status" do
        put move_status_path(b, page: 2, per_page: 2), params: drop_params, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Status.order(:position).pluck(:name)).to eq(%w[A B C D E])
      end

      it "keeps menu moves global" do
        put move_status_path(d, page: 2, per_page: 2), params: { move_to: "highest" }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(Status.order(:position).pluck(:name)).to eq(%w[D A B C E])
        expect(response.body).to include("status-row-#{b.id}", "status-row-#{c.id}")
      end
    end
  end
end
