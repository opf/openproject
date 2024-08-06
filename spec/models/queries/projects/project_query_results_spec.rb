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

RSpec.describe ProjectQuery, "results" do
  let(:instance) { described_class.new }
  let(:base_scope) { Project.order(id: :desc) }

  shared_let(:view_role) { create(:project_role, permissions: %i[view_project]) }
  shared_let(:non_member_role) { create(:non_member, permissions: %i[view_project]) }
  shared_let(:grandparent) { create(:project, name: "Grandparent") }
  shared_let(:parent) { create(:project, parent: grandparent, name: "Parent") }
  shared_let(:child) { create(:project, parent:, name: "Child") }
  shared_let(:grandchild) { create(:project, parent: child, name: "Grandchild") }
  shared_let(:sibling) { create(:project, parent:, name: "Sibling") }
  shared_let(:not_member) { create(:project, name: "Not member") }
  shared_let(:public) { create(:public_project, name: "Public") }
  shared_let(:no_hierarchy) { create(:project, name: "No Hierarchy") }

  shared_let(:user) do
    create(:user, member_with_roles: {
             grandparent => [view_role],
             parent => [view_role],
             child => [view_role],
             grandchild => [view_role],
             sibling => [view_role],
             no_hierarchy => [view_role]
           })
  end

  current_user { user }

  context "without a filter" do
    it "gets all visible projects" do
      expect(instance.results)
        .to contain_exactly(grandparent, parent, child, sibling, grandchild, public, no_hierarchy)
    end
  end

  context "with a parent filter" do
    context 'with a "=" operator' do
      before do
        instance.where("parent_id", "=", [parent.id])
      end

      it "returns all children of the specified parent" do
        expect(instance.results)
          .to contain_exactly(child, sibling)
      end
    end
  end

  context "with an ancestor filter" do
    context 'with a "=" operator' do
      before do
        instance.where("ancestor", "=", [grandparent.id])
      end

      it "gets all projects that are descendants" do
        expect(instance.results)
          .to contain_exactly(parent, child, sibling, grandchild)
      end
    end

    context 'with a "!" operator' do
      before do
        instance.where("ancestor", "!", [grandparent.id])
      end

      it "gets all projects that are not descendants" do
        expect(instance.results)
          .to contain_exactly(grandparent, public, no_hierarchy)
      end
    end
  end

  context "with an order by id asc" do
    it "returns all visible projects ordered by id asc" do
      expect(instance.order(id: :asc).results.to_a)
        .to eql [grandparent, parent, child, sibling, grandchild, public, no_hierarchy].sort_by(&:id)
    end
  end

  context "with an order by typeahead asc" do
    before do
      instance.order(typeahead: :asc)
    end

    it "returns all visible projects ordered by lft asc" do
      expect(instance.results.to_a)
        .to eql [grandparent, parent, child, grandchild, sibling, no_hierarchy, public]
    end
  end
end
