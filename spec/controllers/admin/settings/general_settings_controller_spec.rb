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

RSpec.describe Admin::Settings::GeneralSettingsController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  include_examples "GET #show requires admin permission and renders template", path: "general_settings"

  describe "PATCH #update" do
    it "stores custom protocols and drops schemes that cannot be used in links" do
      patch :update, params: {
        settings: { allowed_link_protocols: "ftp\njavascript\nJavaScript\ndata\nvbscript\n<vbscript>\n" }
      }

      expect(response).to redirect_to(action: "show")
      expect(Setting.allowed_link_protocols).to eq(["ftp"])
    end
  end
end
