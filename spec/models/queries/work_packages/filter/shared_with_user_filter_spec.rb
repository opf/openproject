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

RSpec.describe Queries::WorkPackages::Filter::SharedWithUserFilter do
  create_shared_association_defaults_for_work_package_factory

  describe "#apply_to" do
    shared_let(:work_package_role) { create(:work_package_role, permissions: %i[blurgh]) }

    shared_let(:shared_with_user) { create(:user) }
    shared_let(:other_shared_with_user) { create(:user) }
    shared_let(:non_shared_with_user) { create(:user) }

    shared_let(:shared_work_package) do
      create(:work_package) do |wp|
        create(:member,
               user: shared_with_user,
               project: project_with_types,
               entity: wp,
               roles: [work_package_role])
      end
    end
    shared_let(:other_shared_work_package) do
      create(:work_package) do |wp|
        create(:member,
               user: other_shared_with_user,
               project: project_with_types,
               entity: wp,
               roles: [work_package_role])
      end
    end

    def grant_viewing_permissions
      role = create(:project_role, permissions: %i[view_shared_work_packages])
      user.memberships << create(:member,
                                 project: project_with_types,
                                 roles: [role])
    end

    before_all { grant_viewing_permissions }

    let(:instance) do
      described_class.create!.tap do |filter|
        filter.values = values
        filter.operator = operator
      end
    end

    subject { instance.apply_to(WorkPackage) }

    current_user { user }

    context 'with a "=" operator' do
      let(:operator) { "=" }

      context "for a list of users when none were shared a work package" do
        let(:values) { [non_shared_with_user.id.to_s, user.id.to_s] }

        it "does not return any work package" do
          expect(subject)
            .to be_empty
        end
      end

      context "for a list of users where at least one was shared a work package" do
        let(:values) { [shared_with_user.id.to_s, non_shared_with_user.id.to_s] }

        it "returns the shared work package" do
          expect(subject)
            .to contain_exactly(shared_work_package)
        end
      end

      context "for a list of users where all were shared the same work package" do
        before do
          user.memberships << create(:member,
                                     user:,
                                     entity: shared_work_package,
                                     project: project_with_types,
                                     roles: [work_package_role])
          user.save!
        end

        let(:values) { [shared_with_user.id.to_s, user.id.to_s] }

        it "returns the shared work package" do
          expect(subject)
            .to contain_exactly(shared_work_package)
        end
      end

      context "for a list of users where each was shared a different work package" do
        shared_let(:other_shared_work_package) do
          create(:work_package) do |wp|
            create(:member,
                   user:,
                   entity: wp,
                   project: project_with_types,
                   roles: [work_package_role])
          end
        end

        let(:values) { [shared_with_user.id.to_s, user.id.to_s] }

        it "returns each shared work package" do
          expect(subject)
            .to contain_exactly(shared_work_package, other_shared_work_package)
        end
      end

      context "when the user does not have the :view_shared_work_packages permission" do
        before do
          # Remove all permissions
          user.members.destroy_all

          user.memberships << create(:member,
                                     user:,
                                     entity: shared_work_package,
                                     project: project_with_types,
                                     roles: [work_package_role])
          user.save!
        end

        context "and using `me` as the filter value" do
          let(:values) { ["me"] }

          it "returns the work package shared with me" do
            expect(subject).to contain_exactly(shared_work_package)
          end
        end

        context "and filtering for other users" do
          let(:values) { [non_shared_with_user.id, shared_with_user.id] }

          it "returns the work package shared with me" do
            expect(subject).to be_empty
          end
        end
      end
    end

    context 'with a "&=" operator' do
      let(:operator) { "&=" }

      context "for a list of users where none were shared the work package" do
        let(:values) { [non_shared_with_user.id.to_s, user.id.to_s] }

        it "does not return any work package" do
          expect(subject)
            .to be_empty
        end
      end

      context "for a list of users where some were shared the work package" do
        let(:values) { [shared_with_user.id.to_s, non_shared_with_user.id.to_s] }

        it "does not return any work package" do
          expect(subject)
            .to be_empty
        end
      end

      context "for a list of users where all were shared the work package" do
        before do
          other_shared_with_user.memberships << create(:member,
                                                       user: other_shared_with_user,
                                                       entity: shared_work_package,
                                                       project: project_with_types,
                                                       roles: [work_package_role])
          other_shared_with_user.save!
        end

        let(:values) { [shared_with_user.id.to_s, other_shared_with_user.id.to_s] }

        it "returns the commonly shared work package" do
          expect(subject)
            .to contain_exactly(shared_work_package)
        end
      end
    end

    context 'with a "*" operator' do
      let(:operator) { "*" }
      let(:values) { [] }

      it "returns the shared work package" do
        expect(subject)
          .to contain_exactly(shared_work_package, other_shared_work_package)
      end
    end
  end

  it_behaves_like "basic query filter" do
    let(:type) { :shared_with_user_list_optional }
    let(:class_key) { :shared_with_user }
    let(:human_name) { I18n.t("query_fields.shared_with_user") }

    describe "#available?" do
      context "when I'm logged in" do
        before do
          login_as user
        end

        context "and I have the necessary permissions" do
          before do
            mock_permissions_for(user) do |mock|
              mock.allow_in_project :view_shared_work_packages, project:
            end
          end

          it do
            expect(instance).to be_available
          end
        end

        context "and I don't have the necessary permissions" do
          before do
            mock_permissions_for(user, &:forbid_everything)
          end

          it { expect(instance).not_to be_available }
        end
      end

      context "when I'm not logged in" do
        it { expect(instance).not_to be_available }
      end
    end
  end
end
