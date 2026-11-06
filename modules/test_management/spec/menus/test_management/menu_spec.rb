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

RSpec.describe TestManagement::Menu do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }
  let(:params) { {} }
  let(:menu) { described_class.new(project:, params:, user:) }
  let(:items) { menu.menu_items.first.children }

  describe ".section_for" do
    it "maps the cases controller" do
      expect(described_class.section_for("test_management/test_cases")).to eq("cases")
      expect(described_class.section_for("projects")).to be_nil
    end
  end

  it "lists cases only" do
    expect(items.map(&:href)).to eq([project_test_management_test_cases_path(project)])
  end

  context "without the module" do
    let(:project) { create(:project, enabled_module_names: []) }

    it "is empty" do
      expect(items).to be_empty
    end
  end
end
