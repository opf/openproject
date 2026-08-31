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

RSpec.describe Types::EditPageHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, name: "Apollo") }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Internal") }

  current_user { create(:admin) }

  def render_header
    render_inline(described_class.new(type:, variant:))
  end

  context "when the screen is reached from administration" do
    before { render_header }

    it "leads back through administration" do
      expect(page).to have_link("Administration", href: admin_index_path)
    end

    it "leads back to the list of types" do
      expect(page).to have_link("Types", href: types_path)
    end

    # An administrator may open the type's own configuration, so its name is a way in.
    it "links the parent type" do
      expect(page).to have_link("Bug", href: edit_type_details_path(type_id: type.id))
    end

    it "names the variant being configured" do
      expect(page).to have_text("Internal")
    end
  end

  context "when the screen is reached from a project's settings" do
    before do
      # What the controller sets, and what the trail keys off.
      vc_test_controller.instance_variable_set(:@project, project)
      render_header
    end

    it "leads back through the project, not administration" do
      expect(page).to have_link("Apollo", href: project_overview_path(project.id))
      expect(page).to have_no_link("Administration")
    end

    it "leads back through the project's settings" do
      expect(page).to have_link("Project settings", href: project_settings_general_path(project.id))
    end

    it "leads back to the project's own work package settings" do
      expect(page).to have_link(
        "Work packages",
        href: project_settings_work_packages_types_path(project)
      )
    end

    # The type's own configuration is administration's, so the parent leads back to this
    # project's types rather than to a screen the caller cannot open.
    it "leads the parent type back into the project" do
      expect(page).to have_link("Bug", href: project_settings_work_packages_types_path(project))
    end

    it "offers no way into the type's own configuration" do
      expect(page).to have_no_link(href: edit_type_details_path(type_id: type.id))
    end

    it "still names the variant being configured" do
      expect(page).to have_text("Internal")
    end
  end
end
