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

RSpec.describe Query::Results,
               "Filter on historic data",
               with_ee: %i[baseline_comparison] do
  let(:historic_time) { "2022-08-01".to_datetime }
  let(:pre_historic_time) { historic_time - 1.day }
  let(:recent_time) { 1.hour.ago }
  let!(:work_package) do
    create(:work_package,
           description: "This is the current description of the work package",
           project: project_with_member,
           journals: {
             historic_time => { description: "This is the original description of the work package" },
             recent_time => { description: "This is the current description of the work package" }
           })
  end

  let!(:work_package2) do
    create(:work_package,
           description: "Lorem ipsum",
           project: project_with_member,
           journals: {
             historic_time => { description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit" },
             recent_time => { description: "Lorem ipsum" }
           })
  end

  let(:project_with_member) { create(:project) }
  let(:project_without_member) { create(:project) }

  let(:user1) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_permissions: { project_with_member => %i[view_work_packages view_file_links] })
  end

  def move_work_package_to_project(work_package, project, time)
    work_package.update project:, updated_at: time
    work_package.journals.last.update_columns(created_at: time, updated_at: time)
    work_package.reload
  end

  describe "[prelims]" do
    specify "the work package has a journal entry with the historic description" do
      expect(work_package.journals.count).to eq 2
      expect(work_package.journals.first.data.description).to eq "This is the original description of the work package"
    end

    specify "the work package has its current description" do
      expect(work_package.description).to eq "This is the current description of the work package"
    end
  end

  describe "#work_packages" do
    let(:query) do
      login_as(user1)
      build(:query, user: user1, project: nil).tap do |query|
        query.filters.clear
        query.add_filter "description", "~", search_term
      end
    end
    let(:results) { query.results }

    subject { results.work_packages }

    describe "filter for description containing 'current'" do
      let(:search_term) { "current" }

      it "includes the work package matching today" do
        expect(subject).to eq [work_package]
      end
    end

    describe "filter for description containing 'original'" do
      let(:search_term) { "original" }

      it "does not include the work package matching only in the past" do
        expect(subject).not_to eq [work_package]
      end
    end

    describe "when searching current and historic work packages" do
      before { query.timestamps = [historic_time, Time.zone.now] }

      describe "filter for description containing 'current'" do
        let(:search_term) { "current" }

        it "includes the work package matching today" do
          expect(subject).to eq [work_package]
        end
      end

      describe "filter for description containing 'original'" do
        let(:search_term) { "original" }

        it "includes the work package matching in the past" do
          expect(subject).to eq [work_package]
        end
      end
    end

    describe "when the search matches several work packages" do
      before { query.timestamps = [historic_time, Time.zone.now] }

      let(:search_term) { "re" }

      it "includes all matching work packages" do
        expect(subject).to include work_package, work_package2
      end
    end

    describe "when searching only historic work packages" do
      before { query.timestamps = [historic_time] }

      describe "filter for description containing 'current'" do
        let(:search_term) { "current" }

        it "does not include the work package matching only in the past" do
          expect(subject).not_to include work_package
        end
      end

      describe "filter for description containing 'original'" do
        let(:search_term) { "original" }

        it "includes the work package matching in the past" do
          expect(subject).to include work_package
        end

        it "returns the work packages in their current state" do
          expect(subject.first.description).to eq "This is the current description of the work package"
        end

        describe "when chaining at_timestamp" do
          # https://github.com/opf/openproject/pull/11678#issuecomment-1324244907

          describe "directly" do
            subject { results.work_packages.at_timestamp(historic_time) }

            it "returns the work packages in their historic states" do
              expect(subject.first.description).to eq "This is the original description of the work package"
            end
          end

          describe "using a subquery" do
            subject { WorkPackage.where(id: results.work_packages).at_timestamp(historic_time) }

            it "returns the work packages in their historic states" do
              expect(subject.first.description).to eq "This is the original description of the work package"
            end
          end

          describe "using a pluck-id workaround" do
            subject { WorkPackage.where(id: results.work_packages.pluck(:id)).at_timestamp(historic_time) }

            it "returns the work packages in their historic states" do
              expect(subject.first.description).to eq "This is the original description of the work package"
            end
          end
        end
      end
    end

    describe "when searching only pre-historic work packages (i.e. when the work package does not exist yet)" do
      before { query.timestamps = [pre_historic_time] }

      describe "filter for description containing 'current'" do
        let(:search_term) { "current" }

        it "does not include the work package matching only in the past" do
          expect(subject).not_to include work_package
        end
      end

      describe "filter for description containing 'original'" do
        let(:search_term) { "original" }

        it "does not include the work package because it does not exist yet at that time" do
          expect(subject).not_to include work_package
        end
      end
    end

    describe "when filtering for file links" do
      # https://github.com/opf/openproject/pull/11678#issuecomment-1326171087

      let(:storage1) { create(:nextcloud_storage, creator: user1) }
      let(:query) do
        login_as(user1)
        build(:query, user: user1, project: nil).tap do |query|
          query.filters.clear
          query.add_filter "file_link_origin_id", "=", [file_link1.origin_id.to_s]
        end
      end
      let(:file_link1) { create(:file_link, creator: user1, container: work_package, storage: storage1) }
      let(:project_storage1) { create(:project_storage, project: project_with_member, storage: storage1) }

      before do
        project_storage1
        file_link1
      end

      it "includes the work package" do
        expect(subject).to include work_package
      end

      it "includes the work package only once" do
        expect(subject.uniq).to eq subject
      end

      describe "when having second reference to the same external file" do
        let(:storage2) { create(:nextcloud_storage, creator: user1) }
        let(:project_storage2) { create(:project_storage, project: project_without_member, storage: storage2) }
        let(:file_link2) do
          create(:file_link, creator: user1, container: work_package, storage: storage2, origin_id: file_link1.origin_id)
        end

        before do
          project_storage2
          file_link2
        end

        it "includes the work package" do
          expect(subject).to include work_package
        end

        it "includes the work package only once" do
          expect(subject.uniq).to eq subject
        end
      end
    end

    context "when the work package is moved to a project the user has no permissions in" do
      current_user { user1 }

      let(:query) do
        build(:query, user: user1, project: nil).tap do |query|
          query.filters.clear
          query.timestamps = [historic_time, Time.zone.now]
        end
      end

      before do
        move_work_package_to_project(work_package, project_without_member, 3.minutes.ago)
      end

      it "includes the work package (since the user was able to see it)" do
        expect(subject).to include work_package
      end
    end

    context "when the work package is moved to a project the user has no permissions in " \
            "and also has no permission in the old project" do
      current_user { user1 }

      let(:query) do
        build(:query, user: user1, project: nil).tap do |query|
          query.filters.clear
          query.timestamps = [historic_time, Time.zone.now]
        end
      end

      before do
        move_work_package_to_project(work_package, project_without_member, 3.minutes.ago)
        project_with_member.members.destroy_all
      end

      it "does not include the work package" do
        expect(subject).not_to include work_package
      end
    end

    context "when the work package is moved to a project the user has permissions in " \
            "and looses permission in the former project" do
      current_user { user1 }

      let(:query) do
        build(:query, user: user1, project: nil).tap do |query|
          query.filters.clear
          query.timestamps = [historic_time, Time.zone.now]
        end
      end

      before do
        move_work_package_to_project(work_package, project_without_member, 3.minutes.ago)
        create(:member,
               principal: user1,
               project: project_without_member,
               roles: create_list(:project_role, 1, permissions: %w[view_work_packages]))
        project_with_member.members.destroy_all
      end

      it "includes the work package" do
        expect(subject).to include work_package
      end
    end

    context "when the work package is moved to a project the user has no permissions in" \
            "and the comparison time is after the move" do
      current_user { user1 }

      let(:query) do
        build(:query, user: user1, project: nil).tap do |query|
          query.filters.clear
          query.timestamps = [2.minutes.ago, Time.zone.now]
        end
      end

      before do
        move_work_package_to_project(work_package, project_without_member, 3.minutes.ago)
      end

      it "does not include the work package since the user is not allowed to see the work package at the timestamps" do
        expect(subject).not_to include work_package
      end
    end
  end
end
