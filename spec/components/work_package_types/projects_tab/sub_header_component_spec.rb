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

require "rails_helper"

RSpec.describe WorkPackageTypes::ProjectsTab::SubHeaderComponent, type: :component do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:archived) { create(:project, active: false) }

  let(:query) { ProjectQuery.new(name: "type-projects") }

  before { render_inline(described_class.new(type:, variant: type.default_variant, query:)) }

  context "when every active project uses the type" do
    it "offers to disable it for all projects" do
      expect(page).to have_test_selector("type-projects-enable-all", text: "Disable for all projects")
    end
  end

  context "when an active project does not use the type" do
    shared_let(:other) { create(:project) }

    it "offers to enable it for all projects" do
      expect(page).to have_test_selector("type-projects-enable-all", text: "Enable for all projects")
    end
  end
end
