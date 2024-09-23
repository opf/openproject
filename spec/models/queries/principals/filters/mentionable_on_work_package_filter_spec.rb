# frozen_string_literal: true

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

RSpec.describe Queries::Principals::Filters::MentionableOnWorkPackageFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :mentionable_on_work_package }
    let(:type) { :list_optional }

    describe "#scope" do
      subject { instance.apply_to(Principal) }

      shared_let(:project) { create(:project) }
      shared_let(:other_project) { create(:project) }

      shared_let(:project_role) { create(:project_role, permissions: %i[]) }
      shared_let(:comment_role) { create(:comment_work_package_role) }
      shared_let(:view_role) { create(:view_work_package_role) }

      shared_let(:work_package) { create(:work_package, project:) }

      shared_let(:user) { create(:user, member_with_roles: { project => project_role, other_project => project_role }) }
      shared_let(:project_member) { create(:user, member_with_roles: { project => project_role, other_project => project_role }) }
      shared_let(:mentionable_shared_with_user) { create(:user, member_with_roles: { work_package => comment_role }) }
      shared_let(:non_mentionable_shared_with_user) { create(:user, member_with_roles: { work_package => view_role }) }

      let(:values) { [work_package.id.to_s] }

      let(:instance) do
        described_class.create!.tap do |filter|
          filter.values = values
          filter.operator = operator
        end
      end

      before do
        allow(User)
          .to receive(:current)
                .and_return(user)
      end

      context "with an = operator" do
        let(:operator) { "=" }

        it "returns all mentionable principals on the work package and its project" do
          expect(subject)
            .to contain_exactly(user,
                                mentionable_shared_with_user,
                                project_member)
        end
      end

      context "with a ! operator" do
        let(:operator) { "!" }

        it "returns all non-mentionable users on the work package and its project" do
          expect(subject)
            .to contain_exactly(non_mentionable_shared_with_user)
        end
      end
    end
  end
end
