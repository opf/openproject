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

RSpec.describe WorkPackageTypes::FormConfigurationTabController do
  let(:type) { create(:type) }
  let(:user) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  describe "GET #edit" do
    context "with an unauthorized account" do
      let(:user) { create(:user) }

      before { get "edit", params: { type_id: type.id } }

      it { expect(response).to have_http_status(:forbidden) }
    end

    context "with invalid type id" do
      it "renders a 404" do
        get :edit, params: { type_id: "invalid" }
        expect(response).to have_http_status(:not_found)
      end
    end

    it "renders the edit tab" do
      get :edit, params: { type_id: type.id }
      expect(response).to render_template(:edit)
    end
  end
end
