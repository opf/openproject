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
#++

require "rails_helper"

RSpec.describe Overviews::ShowComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject(:rendered_component) do
    render_component(project:, current_user:)
  end

  shared_examples_for "rendering layout with sidebar" do
    it "renders layout" do
      expect(rendered_component).to have_css ".Layout"
    end

    it "renders main" do
      expect(rendered_component).to have_css ".Layout-main"
    end

    it "renders sidebar" do
      expect(rendered_component).to have_css ".Layout-sidebar"
    end
  end

  shared_examples_for "not rendering layout with sidebar" do
    it "does not render layout" do
      expect(rendered_component).to have_no_css ".Layout"
    end

    it "does not render main" do
      expect(rendered_component).to have_no_css ".Layout-main"
    end

    it "does not render sidebar" do
      expect(rendered_component).to have_no_css ".Layout-sidebar"
    end
  end

  it "renders overview grid" do
    expect(rendered_component).to have_css ".widget-boxes"
  end

  it "does not render widgets" do
    expect(rendered_component).to have_no_element "opce-dashboard"
  end

  context "when project has neither project attributes or life cycle" do
    it_behaves_like "not rendering layout with sidebar"
  end

  context "when project has project attributes" do
    let(:project) { build(:project) }
    let!(:project_custom_fields) { create_list(:project_custom_field, 2, projects: [project]) }

    context "when user does not have permission to view project attributes" do
      it_behaves_like "not rendering layout with sidebar"

      it "does not render sidebar content in turbo frame" do
        expect(rendered_component).to have_no_element "turbo-frame", id: "project-custom-fields-sidebar"
      end
    end

    context "when user has permission to view project attributes" do
      let(:user) { create(:user, member_with_permissions: { project => [:view_project_attributes] }) }

      it_behaves_like "rendering layout with sidebar"

      it "renders sidebar content in turbo frame" do
        expect(rendered_component).to have_element "turbo-frame",
                                                   id: "project-custom-fields-sidebar",
                                                   src: project_custom_fields_sidebar_path(project)
      end
    end
  end

  context "when project has life cycle" do
    let(:project) { build(:project) }
    let!(:project_phase) { create(:project_phase, project:) }

    context "when user does not have permission to view project life cycle" do
      it_behaves_like "not rendering layout with sidebar"

      it "does not render sidebar content in turbo frame" do
        expect(rendered_component).to have_no_element "turbo-frame", id: "project-life-cycle-sidebar"
      end
    end

    context "when user has permission to view project life cycle" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_project_phases, project:)
        end
      end

      it_behaves_like "rendering layout with sidebar"

      it "renders sidebar content in turbo frame" do
        expect(rendered_component).to have_element "turbo-frame",
                                                   id: "project-life-cycle-sidebar",
                                                   src: project_life_cycle_sidebar_path(project)
      end
    end
  end
end
