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

require "rails_helper"

RSpec.describe Admin::SettingsSearchComponent, type: :component do
  subject(:rendered_component) do
    render_inline(described_class.new)
    page
  end

  context "as an admin" do
    current_user { build_stubbed(:admin) }

    it "renders a button opening the lazily loaded settings tree", :aggregate_failures do
      expect(rendered_component).to have_button "Search settings"
      expect(rendered_component).to have_css("turbo-frame[src='/admin/settings_search'][loading='lazy']", visible: :all)
    end
  end

  context "as a regular user" do
    current_user { build_stubbed(:user) }

    it "renders nothing" do
      expect(rendered_component).to have_no_css("*")
    end
  end
end
