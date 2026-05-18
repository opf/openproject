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

RSpec.describe Queries::WorkPackages::Filter::AncestralFilter do
  let(:project) { build_stubbed(:project) }
  let(:query) do
    build_stubbed(:query, project:)
  end

  it_behaves_like "basic query filter" do
    let(:class_key) { :ancestral }
    let(:type) { :list }

    before do
      instance.context = query
    end

    describe "#where and #includes" do
      let(:grandparent) { create(:work_package) }
      let(:parent) { create(:work_package, parent: grandparent) }
      let(:child) { create(:work_package, parent:) }
      let(:grandchild) { create(:work_package, parent: child) }
      let(:another_wp) { create(:work_package) }

      before do
        grandchild
        another_wp
        instance.values = [parent.id.to_s]
        instance.operator = "="
      end

      it "includes the selected ancestor and all its descendants" do
        scope = WorkPackage
                .references(instance.includes)
                .includes(instance.includes)
                .where(instance.where)

        expect(scope).to contain_exactly(parent, child, grandchild)
      end

      it "does not include work packages outside the hierarchy" do
        scope = WorkPackage
                .references(instance.includes)
                .includes(instance.includes)
                .where(instance.where)

        expect(scope).not_to include(grandparent, another_wp)
      end

      context "with the `!` operator" do
        before do
          instance.operator = "!"
        end

        it "excludes the ancestor and all its descendants" do
          scope = WorkPackage
                    .references(instance.includes)
                    .includes(instance.includes)
                    .where(instance.where)

          expect(scope).to contain_exactly(grandparent, another_wp)
        end
      end
    end
  end
end
