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

RSpec.describe Projects::Scopes::SelfAndAncestorsOf do
  shared_let(:root) { create(:project, name: "Root") }
  shared_let(:child) { create(:project, name: "Child", parent: root) }
  shared_let(:grandchild) { create(:project, name: "Grandchild", parent: child) }
  shared_let(:sibling) { create(:project, name: "Sibling", parent: root) }
  shared_let(:other_root) { create(:project, name: "Other root") }

  def names_of(projects) = Project.order(:lft).self_and_ancestors_of(projects).map(&:name)

  it "returns the projects with all their ancestors, in tree order" do
    expect(names_of(Project.where(id: grandchild))).to eq(%w[Root Child Grandchild])
  end

  it "returns a shared ancestor once" do
    expect(names_of(Project.where(id: [grandchild, sibling]))).to eq(%w[Root Child Grandchild Sibling])
  end

  it "leaves out the descendants of the projects" do
    expect(names_of(Project.where(id: child))).to eq(%w[Root Child])
  end

  it "returns nothing for no projects" do
    expect(names_of(Project.none)).to be_empty
  end
end
