# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Queries::WorkPackages::Filter::SharedWithMeFilter do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:work_package_role) { create(:work_package_role, permissions: %i[view_work_packages]) }

  shared_let(:shared_with_user) { create(:user) }
  shared_let(:non_shared_with_user) { create(:user) }

  shared_let(:shared_work_package) do
    create(:work_package, project: project_with_types) do |wp|
      create(:member, user: shared_with_user, project: project_with_types, entity: wp, roles: [work_package_role])
    end
  end

  let(:query) { Query.new }

  let(:instance) { described_class.create!(context: query, values: ["t"], operator: "=") }

  subject { instance }

  describe "#available?" do
    context "when the query is not scoped to a project" do
      context "when the user has work packages shared with them" do
        current_user { shared_with_user }
        it { is_expected.to be_available }
      end

      context "when the user does not have work packages shared with them" do
        current_user { non_shared_with_user }
        it { is_expected.not_to be_available }
      end
    end

    context "when the query is scoped to a project" do
      current_user { shared_with_user }

      context "and the user has work packages shared with them in the project" do
        before { query.project = project_with_types }

        it { is_expected.to be_available }
      end

      context "and the user does not have work packages shared with them in the project" do
        before { query.project = create(:project) }

        it { is_expected.not_to be_available }
      end
    end
  end

  describe "#where" do
    subject { WorkPackage.where(instance.where) }

    context "when the user has work packages shared with them" do
      current_user { shared_with_user }

      let!(:other_work_package) do
        create(:work_package, project: project_with_types)
      end

      it { is_expected.to contain_exactly(shared_work_package) }
    end

    context "when the user has no work packages shared with them" do
      current_user { non_shared_with_user }

      it { is_expected.to be_empty }
    end
  end
end
