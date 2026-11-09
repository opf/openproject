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

RSpec.describe Projects::InfoLineComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project, name: "Arcanos Flight Planning", workspace_type: :program) }
  let(:show_workspace_type) { false }

  subject(:rendered_component) { render_inline(described_class.new(project:, show_workspace_type:)) }

  it "links the project name" do
    expect(rendered_component).to have_link("Arcanos Flight Planning", href: project_path(project))
  end

  it "leaves out the workspace type unless asked for" do
    expect(rendered_component).to have_no_test_selector("project-info-line-workspace-type")
  end

  it "leaves out the archived label for an active project" do
    expect(rendered_component).to have_no_css(".Label")
  end

  context "when asked to show the workspace type" do
    let(:show_workspace_type) { true }

    it "names the workspace type with its icon" do
      expect(rendered_component).to have_test_selector("project-info-line-workspace-type", text: I18n.t(:label_program))
      expect(rendered_component).to have_css("[data-test-selector='project-info-line-workspace-type'] svg.octicon-versions")
    end
  end

  context "for an archived project" do
    let(:project) { build_stubbed(:project, name: "Arcanos Flight Planning", active: false) }

    it "labels it as archived" do
      expect(rendered_component).to have_css(".Label", text: I18n.t("project.archive.archived"))
    end

    it "names it without linking to it" do
      expect(rendered_component).to have_text("Arcanos Flight Planning")
      expect(rendered_component).to have_no_link("Arcanos Flight Planning")
    end
  end
end
