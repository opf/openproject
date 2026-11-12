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
#++

require "spec_helper"

RSpec.describe "Renaming a form or a workflow", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  current_user { admin }

  shared_examples "a rename returning where it started" do
    def rename(referer: nil)
      patch(polymorphic_path(record), params: { record.model_name.param_key => { name: "Renamed" } },
                                      headers: headers.merge("Referer" => referer).compact)
    end

    it "returns to the filtered index the dialog was opened from", :aggregate_failures do
      index = "http://test.host#{index_path}?filters=%5B%5D"
      rename(referer: index)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(index)
      expect(record.reload.name).to eq("Renamed")
    end

    it "returns to the edit page the dialog was opened from" do
      edit = "http://test.host#{edit_polymorphic_path(record)}"
      rename(referer: edit)

      expect(response).to redirect_to(edit)
    end

    it "falls back to the edit page without a referer" do
      rename

      expect(response).to redirect_to(edit_polymorphic_path(record))
    end
  end

  describe "a form" do
    let(:record) { create(:form_configuration, name: "Hardware form") }
    let(:index_path) { form_configurations_path }

    it_behaves_like "a rename returning where it started"
  end

  describe "a workflow" do
    let(:record) { create(:named_workflow, name: "Hardware flow") }
    let(:index_path) { workflows_path }

    it_behaves_like "a rename returning where it started"
  end
end
