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

require "spec_helper"

RSpec.describe "auto-rendered settings page routes" do
  Settings::Pages.routed.each do |settings_page|
    context "for the #{settings_page.key} page" do
      let(:path) { "/admin/settings/#{settings_page.key}" }
      let(:target) { { controller: "admin/settings/pages", settings_page: settings_page.key.to_s } }

      it "routes GET to the page" do
        expect(get(path)).to route_to(**target, action: "show")
      end

      it "routes PATCH to the page" do
        expect(patch(path)).to route_to(**target, action: "update")
      end

      it "generates the path from the page's controller and key" do
        expect(url_for(**target, action: "show", only_path: true)).to eq path
      end
    end
  end
end
