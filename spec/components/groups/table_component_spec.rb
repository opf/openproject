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

RSpec.describe Groups::TableComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) do
    render_component(rows: groups)
  end

  shared_examples_for "rendering Border Box Grid headings" do
    include_examples "rendering Border Box Grid heading", text: "Name"
    include_examples "rendering Border Box Grid heading", text: "User count"
    include_examples "rendering Border Box Grid heading", text: "Created on"
    include_examples "rendering Border Box Grid mobile heading", text: "Group"
  end

  context "with no groups" do
    let(:groups) { create_list(:group, 0) }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Blank Slate", heading: "No groups set up yet", icon: :people
  end

  context "with groups" do
    let(:groups) { create_list(:group, 2) }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 3
  end

  context "with nested groups" do
    let(:parent_group) do
      create(:group, lastname: "Parent").tap { |g| g.hierarchy_depth = 0 }
    end
    let(:child_group) do
      create(:group, lastname: "Child", parent: parent_group).tap { |g| g.hierarchy_depth = 1 }
    end
    let(:groups) { [parent_group, child_group] }

    it "renders child groups with indentation and arrow icon" do
      expect(rendered_component).to have_css("span[style='margin-left: 20px']")
      expect(rendered_component).to have_css("span[style='margin-left: 20px'] a", text: "Child")
    end

    it "renders parent groups without indentation" do
      expect(rendered_component).to have_link("Parent")
      expect(rendered_component).to have_no_css("span[style='margin-left: 0px']")
    end
  end
end
