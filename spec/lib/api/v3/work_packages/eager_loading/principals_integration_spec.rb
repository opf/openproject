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
require_relative "eager_loading_mock_wrapper"

RSpec.describe API::V3::WorkPackages::EagerLoading::Principals do
  shared_let(:author) { create(:user, firstname: "Arthur", lastname: "Author") }

  describe ".apply" do
    def create_and_unload_associations(*args)
      create(*args).reload
    end

    def user_associations(work_package)
      %i[author assigned_to responsible].map { |association| work_package.association(association) }
    end

    context "when work package references users" do
      shared_let(:astor) { create(:user, firstname: "Astor", lastname: "Assigned to") }
      shared_let(:robert) { create(:user, firstname: "Robert", lastname: "Responsible") }

      let(:work_package) do
        create_and_unload_associations(:work_package, author:,
                                                      assigned_to: astor,
                                                      responsible: robert)
      end

      it "preloads them" do
        expect do
          EagerLoadingMockWrapper.wrap(described_class, [work_package])
        end.to change { user_associations(work_package).map(&:loaded?) }
          .from([false, false, false])
          .to([true, true, true])

        expect(work_package.author).to eq author
        expect(work_package.assigned_to).to eq astor
        expect(work_package.responsible).to eq robert
      end
    end

    context "when work package references groups" do
      let(:group1) { create(:group, firstname: "Group 1") }
      let(:group2) { create(:group, firstname: "Group 2") }

      let(:work_package) do
        create_and_unload_associations(:work_package, author:,
                                                      assigned_to: group1,
                                                      responsible: group2)
      end

      it "preloads them" do
        expect do
          EagerLoadingMockWrapper.wrap(described_class, [work_package])
        end.to change { user_associations(work_package).map(&:loaded?) }
          .from([false, false, false])
          .to([true, true, true])

        expect(work_package.author).to eq author
        expect(work_package.assigned_to).to eq group1
        expect(work_package.responsible).to eq group2
      end
    end

    context "when work package references placeholder users" do
      let(:placeholder_user1) { create(:placeholder_user, firstname: "Placeholder user 1") }
      let(:placeholder_user2) { create(:placeholder_user, firstname: "Placeholder user 2") }

      let(:work_package) do
        create_and_unload_associations(:work_package, author:,
                                                      assigned_to: placeholder_user1,
                                                      responsible: placeholder_user2)
      end

      it "preloads them" do
        expect do
          EagerLoadingMockWrapper.wrap(described_class, [work_package])
        end.to change { user_associations(work_package).map(&:loaded?) }
          .from([false, false, false])
          .to([true, true, true])

        expect(work_package.author).to eq author
        expect(work_package.assigned_to).to eq placeholder_user1
        expect(work_package.responsible).to eq placeholder_user2
      end
    end
  end
end
