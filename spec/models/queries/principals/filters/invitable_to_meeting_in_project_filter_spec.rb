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

RSpec.describe Queries::Principals::Filters::InvitableToMeetingInProjectFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :invitable_to_meeting_in_project }
    let(:type) { :list_optional }
    let(:human_name) { "invitable_to_meeting" }

    describe "#scope" do
      subject { instance.apply_to(Principal) }

      shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
      shared_let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }

      shared_let(:view_meetings_role) { create(:project_role, permissions: %i[view_meetings]) }
      shared_let(:no_meetings_role) { create(:project_role, permissions: %i[view_work_packages]) }

      shared_let(:user) do
        create(:user, member_with_roles: { project => view_meetings_role, other_project => view_meetings_role })
      end
      shared_let(:user_with_view_meetings) { create(:user, member_with_roles: { project => view_meetings_role }) }
      shared_let(:user_without_view_meetings) { create(:user, member_with_roles: { project => no_meetings_role }) }
      shared_let(:user_in_other_project) { create(:user, member_with_roles: { other_project => view_meetings_role }) }

      let(:values) { [project.id.to_s] }

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

        it "returns all principals with view_meetings permission in the project" do
          expect(subject)
            .to contain_exactly(user, user_with_view_meetings)
        end

        context "with multiple project ids" do
          let(:values) { [project.id.to_s, other_project.id.to_s] }

          it "returns principals with view_meetings permission in any of the projects" do
            expect(subject)
              .to contain_exactly(user, user_with_view_meetings, user_in_other_project)
          end
        end
      end

      context "with a ! operator" do
        let(:operator) { "!" }

        it "returns all principals without view_meetings permission in the project" do
          expect(subject)
            .to contain_exactly(user_without_view_meetings, user_in_other_project)
        end
      end
    end
  end
end
