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

RSpec.describe CustomFieldsController do
  shared_let(:admin) { create(:admin) }

  let(:custom_field) { build_stubbed(:custom_field) }

  before do
    login_as admin
  end

  describe "POST edit" do
    before do
      allow(CustomField).to receive(:find).and_return(custom_field)
      allow(custom_field).to receive(:save).and_return(true)
    end

    describe "WITH all ok params" do
      let(:params) do
        {
          "custom_field" => { "name" => "Issue Field" }
        }
      end

      before do
        put :update, params: params.merge(id: custom_field.id)
      end

      it "works" do
        expect(response).to be_redirect
        expect(custom_field.name).to eq("Issue Field")
      end
    end
  end

  describe "POST new" do
    describe "WITH empty name param" do
      let(:params) do
        {
          "type" => "WorkPackageCustomField",
          "custom_field" => {
            "name" => "",
            "field_format" => "string"
          }
        }
      end

      before do
        post :create, params:
      end

      it "responds with error" do
        expect(response).to render_template "new"
        expect(assigns(:custom_field).errors.messages[:name].first).to eq("can't be blank.")
      end
    end

    describe "WITH all ok params" do
      let(:params) do
        {
          "type" => "WorkPackageCustomField",
          "custom_field" => {
            "name" => "field",
            "field_format" => "string"
          }
        }
      end

      before do
        post :create, params:
      end

      it "responds ok" do
        expect(response).to be_redirect
        expect(CustomField.last.name).to eq "field"
      end
    end
  end
end
