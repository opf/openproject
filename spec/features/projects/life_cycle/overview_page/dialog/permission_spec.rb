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

require "spec_helper"
require_relative "../shared_context"

RSpec.describe "Edit project phases on project overview page", :js do
  include_context "with seeded projects and phases"
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:overview_page) { Pages::Projects::Show.new(project) }
  let(:permissions) { [] }

  current_user { user }

  before do
    overview_page.visit_page
  end

  describe "with insufficient View phases permissions" do
    let(:permissions) { %i[view_project] }

    it "does not show the attributes sidebar" do
      overview_page.expect_no_visible_sidebar
    end
  end

  describe "with sufficient View phases permissions" do
    let(:permissions) { %i[view_project view_project_phases] }

    it "shows the attributes sidebar" do
      overview_page.within_life_cycle_sidebar do
        expect(page).to have_text("Project life cycle")
      end
    end
  end

  describe "with Edit project permissions" do
    let(:permissions) { %i[view_project view_project_phases edit_project] }

    it "does not show the edit buttons" do
      overview_page.within_life_cycle_sidebar do
        project_life_cycles.each do |lc|
          expect(page).to have_no_link(href: edit_project_phase_path(lc))
        end
      end
    end
  end

  describe "with sufficient Edit phases permissions" do
    let(:permissions) { %i[view_project view_project_phases edit_project edit_project_phases] }

    it "shows the edit buttons" do
      overview_page.within_life_cycle_sidebar do
        project_life_cycles.each do |lc|
          expect(page).to have_link(href: edit_project_phase_path(lc))
        end
      end
    end
  end
end
