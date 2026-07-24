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

RSpec.describe Project, ".project_tree" do
  shared_let(:root_b) { create(:project, name: "Root B") }
  shared_let(:root_a) { create(:project, name: "Root A") }

  shared_let(:child_z) { create(:project, name: "Z Child", parent: root_a) }
  shared_let(:child_m) { create(:project, name: "M Child", parent: root_a) }
  shared_let(:child_a) { create(:project, name: "A Child", parent: root_a) }

  let(:projects) { described_class.reorder(:lft) }

  def tree(sibling_order: nil)
    result = []
    Project.project_tree(projects, sibling_order:) { |project, level| result << [project.name, level] }
    result
  end

  context "without a sibling_order" do
    it "sorts siblings by name, case-insensitively (the historic default)" do
      expect(tree).to eq(
        [
          ["Root A", 0],
          ["A Child", 1],
          ["M Child", 1],
          ["Z Child", 1],
          ["Root B", 0]
        ]
      )
    end
  end

  context "with a sibling_order" do
    it "sorts siblings within each hierarchy level by the given rank instead of by name" do
      sibling_order = {
        root_b.id => 0,
        root_a.id => 1,
        child_z.id => 0,
        child_m.id => 1,
        child_a.id => 2
      }

      expect(tree(sibling_order:)).to eq(
        [
          ["Root B", 0],
          ["Root A", 0],
          ["Z Child", 1],
          ["M Child", 1],
          ["A Child", 1]
        ]
      )
    end
  end
end
