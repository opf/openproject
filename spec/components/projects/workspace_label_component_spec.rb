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

RSpec.describe Projects::WorkspaceLabelComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build_stubbed(:project, workspace_type:) }
  let(:workspace_type) { :project }

  subject(:rendered_component) do
    render_component(project:)
  end

  context "when the workspace is a project" do
    let(:workspace_type) { :project }

    it "renders the project label" do
      expect(rendered_component).to have_text "Project"
    end
  end

  context "when the workspace is a program" do
    let(:workspace_type) { :program }

    it "renders the program label" do
      expect(rendered_component).to have_text "Program"
    end
  end

  context "when the workspace is a portfolio" do
    let(:workspace_type) { :portfolio }

    it "renders the portfolio label" do
      expect(rendered_component).to have_text "Portfolio"
    end
  end

  it "renders an icon" do
    expect(rendered_component).to have_css "svg.octicon"
  end

  context "with system arguments" do
    subject(:rendered_component) do
      render_component(project:, classes: "my-custom-class")
    end

    it "forwards them to the wrapper" do
      expect(rendered_component).to have_css ".my-custom-class"
    end
  end
end
