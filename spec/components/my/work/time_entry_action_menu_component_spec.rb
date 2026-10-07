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

RSpec.describe My::Work::TimeEntryActionMenuComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking costs]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_project view_work_packages log_own_time edit_own_time_entries] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:time_entry) { create(:time_entry, user:, entity: work_package) }
  let(:navigation) { false }

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(time_entry:, navigation:)) }

  it "offers to edit and to delete the time entry" do
    expect(rendered_component).to have_link("Edit time entry", href: /dialog/)
    expect(rendered_component).to have_link("Delete time entry")
    expect(rendered_component).to have_no_link("Open work package")
  end

  context "with a running timer" do
    let(:time_entry) { create(:time_entry, user:, entity: work_package, ongoing: true, hours: nil) }

    it "offers to stop it instead of editing it" do
      expect(rendered_component).to have_link(I18n.t("button_stop_timer"))
      expect(rendered_component).to have_no_link("Edit time entry")
    end
  end

  context "with navigation" do
    let(:navigation) { true }

    it "links to the work package and its project" do
      expect(rendered_component).to have_link("Open work package", href: "/work_packages/#{work_package.id}")
      expect(rendered_component).to have_link("Open project", href: "/projects/#{project.identifier}")
    end

    context "when the time entry is not logged on a work package" do
      let(:time_entry) { create(:time_entry, :on_meeting, user:) }

      it "still links to its project" do
        expect(rendered_component).to have_link("Open project", href: "/projects/#{time_entry.project.identifier}")
        expect(rendered_component).to have_no_link("Open work package")
      end
    end
  end

  context "when rendering the items only" do
    subject(:rendered_component) do
      render_inline(described_class.new(time_entry:, navigation: true, list_only: true))
    end

    it "renders the list of the menu without a menu around it" do
      expect(rendered_component).to have_css("ul[role='menu']")
      expect(rendered_component).to have_no_css("action-menu")
      expect(rendered_component).to have_link("Open work package")
      expect(rendered_component).to have_link("Edit time entry")
    end
  end

  context "when the user may neither edit nor delete the time entry" do
    let(:permissions) { %i[view_project view_work_packages] }

    it "renders no menu" do
      expect(rendered_component.to_html).to be_blank
    end

    context "with navigation" do
      let(:navigation) { true }

      it "still offers the links" do
        expect(rendered_component).to have_link("Open work package")
        expect(rendered_component).to have_no_link("Edit time entry")
      end
    end
  end
end
