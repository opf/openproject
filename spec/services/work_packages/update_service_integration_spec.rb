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

RSpec.describe WorkPackages::UpdateService, "integration", type: :model do
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) do
    %i(view_work_packages edit_work_packages add_work_packages move_work_packages manage_subtasks)
  end

  let(:status) { create(:default_status) }
  let(:type) { create(:type_standard) }
  let(:project_types) { [type] }
  let(:project) { create(:project, types: project_types) }
  let(:priority) { create(:priority) }
  let(:work_package_attributes) do
    { project_id: project.id,
      type_id: type.id,
      author_id: user.id,
      status_id: status.id,
      priority: }
  end
  let(:work_package) do
    create(:work_package,
           work_package_attributes)
  end
  let(:parent_work_package) do
    create(:work_package,
           work_package_attributes).tap do |w|
      w.children << work_package
      work_package.reload
    end
  end
  let(:grandparent_work_package) do
    create(:work_package,
           work_package_attributes).tap do |w|
      w.children << parent_work_package
    end
  end
  let(:sibling1_attributes) do
    work_package_attributes.merge(parent: parent_work_package)
  end
  let(:sibling2_attributes) do
    work_package_attributes.merge(parent: parent_work_package)
  end
  let(:sibling1_work_package) do
    create(:work_package,
           sibling1_attributes)
  end
  let(:sibling2_work_package) do
    create(:work_package,
           sibling2_attributes)
  end
  let(:child_attributes) do
    work_package_attributes.merge(parent: work_package)
  end
  let(:child_work_package) do
    create(:work_package,
           child_attributes)
  end
  let(:grandchild_attributes) do
    work_package_attributes.merge(parent: child_work_package)
  end
  let(:grandchild_work_package) do
    create(:work_package,
           grandchild_attributes)
  end
  let(:instance) do
    described_class.new(user:,
                        model: work_package)
  end

  subject do
    instance.call(**attributes.merge(send_notifications: false).symbolize_keys)
  end

  describe "updating subject" do
    let(:attributes) { { subject: "New subject" } }

    it "updates the subject" do
      expect(subject)
        .to be_success

      expect(work_package.subject)
        .to eql(attributes[:subject])
    end
  end

  context "when updating the project" do
    let(:target_project) do
      p = create(:project,
                 types: target_types,
                 parent: target_parent)

      create(:member,
             user:,
             project: p,
             roles: [create(:project_role, permissions: target_permissions)])

      p
    end
    let(:attributes) { { project_id: target_project.id } }
    let(:target_permissions) { [:move_work_packages] }
    let(:target_parent) { nil }
    let(:target_types) { [type] }

    it "is is success and updates the project" do
      expect(subject).to be_success
      expect(work_package.reload.project).to eql target_project
    end

    context "with missing permissions" do
      let(:target_permissions) { [] }

      it "is failure" do
        expect(subject).to be_failure
      end
    end

    describe "time_entries" do
      let!(:time_entries) do
        create_list(:time_entry, 2, project:, work_package:)
      end

      it "moves the time entries along" do
        expect(subject)
          .to be_success

        expect(TimeEntry.where(id: time_entries.map(&:id)).pluck(:project_id).uniq)
          .to contain_exactly(target_project.id)
      end
    end

    describe "memberships" do
      let(:wp_role) { create(:work_package_role, permissions: [:view_work_packages]) }
      let(:other_user) { create(:user) }
      let!(:membership) do
        create(:member, project:, entity: work_package, principal: other_user, roles: [wp_role])
      end

      it "moves memberships for the entity to the new project" do
        expect do
          subject
          membership.reload
        end.to change(membership, :project).from(project).to(target_project)
      end

      describe "when the work package has descendents" do
        let!(:child_membership) do
          create(:member, project:, entity: child_work_package, principal: other_user, roles: [wp_role])
        end

        it "moves memberships for the entity and its descendents to the new project" do
          expect do
            subject
            membership.reload
            child_membership.reload
          end.to change(membership, :project).from(project).to(target_project).and \
            change(child_membership, :project).from(project).to(target_project)
        end
      end
    end

    describe "categories" do
      let(:category) do
        create(:category,
               project:)
      end

      before do
        work_package.category = category
        work_package.save!
      end

      context "with equally named category" do
        let!(:target_category) do
          create(:category,
                 name: category.name,
                 project: target_project)
        end

        it "replaces the current category by the equally named one" do
          expect(subject)
            .to be_success

          expect(subject.result.category)
            .to eql target_category
        end
      end

      context "without a target category" do
        let!(:other_category) do
          create(:category,
                 project: target_project)
        end

        it "removes the category" do
          expect(subject)
            .to be_success

          expect(subject.result.category)
            .to be_nil
        end
      end
    end

    describe "version" do
      let(:sharing) { "none" }
      let(:version) do
        create(:version,
               status: "open",
               project:,
               sharing:)
      end
      let(:work_package) do
        create(:work_package,
               version:,
               project:)
      end

      context "with an unshared version" do
        it "removes the version" do
          expect(subject)
            .to be_success

          expect(subject.result.version)
            .to be_nil
        end
      end

      context "with a system wide shared version" do
        let(:sharing) { "system" }

        it "keeps the version" do
          expect(subject)
            .to be_success

          expect(subject.result.version)
            .to eql version
        end
      end

      context "when moving the work package in project hierarchy" do
        let(:target_parent) do
          project
        end

        context "with an unshared version" do
          it "removes the version" do
            expect(subject)
              .to be_success

            expect(subject.result.version)
              .to be_nil
          end
        end

        context "with a shared version" do
          let(:sharing) { "tree" }

          it "keeps the version" do
            expect(subject)
              .to be_success

            expect(subject.result.version)
              .to eql version
          end
        end
      end
    end

    describe "type" do
      let(:target_types) { [type, other_type] }
      let(:other_type) { create(:type) }
      let(:default_type) { type }
      let(:project_types) { [type, other_type] }
      let!(:workflow_type) do
        create(:workflow, type: default_type, role:, old_status_id: status.id)
      end
      let!(:workflow_other_type) do
        create(:workflow, type: other_type, role:, old_status_id: status.id)
      end

      context "with the type existing in the target project" do
        it "keeps the type" do
          expect(subject)
            .to be_success

          expect(subject.result.type)
            .to eql type
        end
      end

      context "with a default type existing in the target project" do
        let(:target_types) { [other_type, default_type] }

        it "uses the default type" do
          expect(subject)
            .to be_success

          expect(subject.result.type)
            .to eql default_type
        end
      end

      context "with only non default types" do
        let(:target_types) { [other_type] }

        it "is unsuccessful" do
          expect(subject)
            .to be_failure
        end
      end

      context "with an invalid type being provided" do
        let(:target_types) { [type] }

        let(:attributes) do
          { project: target_project,
            type: other_type }
        end

        it "is unsuccessful" do
          expect(subject)
            .to be_failure
        end
      end
    end

    describe "relations" do
      let!(:relation) do
        create(:follows_relation,
               from: work_package,
               to: create(:work_package,
                          project:))
      end

      context "with cross project relations allowed", with_settings: { cross_project_work_package_relations: true } do
        it "keeps the relation" do
          expect(subject)
            .to be_success

          expect(Relation.find_by(id: relation.id))
            .to eql(relation)
        end
      end

      context "with cross project relations disabled", with_settings: { cross_project_work_package_relations: false } do
        it "deletes the relation" do
          expect(subject)
            .to be_success

          expect(Relation.find_by(id: relation.id))
            .to be_nil
        end
      end
    end
  end

  describe "inheriting dates" do
    let(:attributes) { { start_date: Time.zone.today - 8.days, due_date: Time.zone.today + 12.days } }
    let(:sibling1_attributes) do
      work_package_attributes.merge(start_date: Time.zone.today - 5.days,
                                    due_date: Time.zone.today + 10.days,
                                    parent: parent_work_package)
    end
    let(:sibling2_attributes) do
      work_package_attributes.merge(due_date: Time.zone.today + 16.days,
                                    parent: parent_work_package)
    end

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
      sibling2_work_package
    end

    it "works and inherits" do
      expect(subject)
        .to be_success

      # receives the provided start/finish date
      expect(work_package)
        .to have_attributes(start_date: attributes[:start_date],
                            due_date: attributes[:due_date])

      # receives the min/max of the children's start/finish date
      [parent_work_package,
       grandparent_work_package].each do |wp|
        wp.reload
        expect(wp)
          .to have_attributes(start_date: attributes[:start_date],
                              due_date: sibling2_work_package.due_date)
      end

      # sibling dates are unchanged
      sibling1_work_package.reload
      expect(sibling1_work_package)
        .to have_attributes(start_date: sibling1_attributes[:start_date],
                            due_date: sibling1_attributes[:due_date])

      sibling2_work_package.reload
      expect(sibling2_work_package)
        .to have_attributes(start_date: sibling2_attributes[:start_date],
                            due_date: sibling2_attributes[:due_date])

      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "inheriting done_ratio" do
    let(:attributes) { { estimated_hours: 10.0, remaining_hours: 5.0 } }
    let(:work_package_attributes) do
      { project_id: project.id,
        type_id: type.id,
        author_id: user.id,
        status_id: status.id,
        priority: }
    end

    let(:sibling1_attributes) do
      work_package_attributes.merge(parent: parent_work_package)
    end
    let(:sibling2_attributes) do
      work_package_attributes.merge(estimated_hours: 100.0,
                                    remaining_hours: 25.0,
                                    parent: parent_work_package)
    end

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
      sibling2_work_package
    end

    it "works and inherits average done ratio of leaves weighted by work values" do
      expect(subject)
        .to be_success

      # sets it to the computation between estimated_hours and remaining_hours
      expect(work_package.done_ratio)
        .to eq(50)

      [parent_work_package,
       grandparent_work_package].each do |wp|
        wp.reload

        # sibling1 not factored in as its estimated and remaining hours are nil
        #
        # Total factored in estimated_hours (work_package + sibling2) = 110
        # Total factored in remaining_hours (work_package + sibling2) = 30
        # Work done = 80
        # Calculated done ratio rounded up = (80 / 110) * 100
        expect(wp.derived_done_ratio)
          .to eq(73)
      end

      # unchanged
      sibling1_work_package.reload
      expect(sibling1_work_package.done_ratio)
        .to be_nil

      sibling2_work_package.reload
      expect(sibling2_work_package.done_ratio)
        .to eq(75) # Was not changed as

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "inheriting estimated_hours" do
    let(:attributes) { { estimated_hours: 7 } }
    let(:sibling1_attributes) do
      # no estimated hours
      work_package_attributes.merge(parent: parent_work_package)
    end
    let(:sibling2_attributes) do
      work_package_attributes.merge(estimated_hours: 5,
                                    parent: parent_work_package)
    end
    let(:child_attributes) do
      work_package_attributes.merge(estimated_hours: 10,
                                    parent: work_package)
    end

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
      sibling2_work_package
      child_work_package
    end

    it "works and inherits" do
      expect(subject)
        .to be_success

      # receives the provided value
      expect(work_package.estimated_hours)
        .to eql(attributes[:estimated_hours].to_f)

      # receive the sum of the children's estimated hours
      [parent_work_package,
       grandparent_work_package].each do |wp|
        sum = sibling1_attributes[:estimated_hours].to_f +
              sibling2_attributes[:estimated_hours].to_f +
              attributes[:estimated_hours].to_f +
              child_attributes[:estimated_hours].to_f

        wp.reload

        expect(wp.estimated_hours).to be_nil
        expect(wp.derived_estimated_hours).to eql(sum)
      end

      # sibling hours are unchanged
      sibling1_work_package.reload
      expect(sibling1_work_package.estimated_hours)
        .to be_nil

      sibling2_work_package.reload
      expect(sibling2_work_package.estimated_hours)
        .to eql(sibling2_attributes[:estimated_hours].to_f)

      # child hours are unchanged
      child_work_package.reload
      expect(child_work_package.estimated_hours)
        .to eql(child_attributes[:estimated_hours].to_f)

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "inheriting ignore_non_working_days" do
    let(:attributes) { { ignore_non_working_days: true } }

    before do
      parent_work_package
      grandparent_work_package
      sibling1_work_package
    end

    it "propagates the value up the ancestor chain" do
      expect(subject)
        .to be_success

      # receives the provided value
      expect(work_package.reload.ignore_non_working_days)
        .to be_truthy

      # parent and grandparent receive the value
      expect(parent_work_package.reload.ignore_non_working_days)
        .to be_truthy
      expect(grandparent_work_package.reload.ignore_non_working_days)
        .to be_truthy

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, parent_work_package, grandparent_work_package)
    end
  end

  describe "closing duplicates on closing status" do
    let(:status_closed) do
      create(:status,
             is_closed: true).tap do |status_closed|
        create(:workflow,
               old_status: status,
               new_status: status_closed,
               type:,
               role:)
      end
    end
    let!(:duplicate_work_package) do
      create(:work_package,
             work_package_attributes).tap do |wp|
        create(:relation, relation_type: Relation::TYPE_DUPLICATES, from: wp, to: work_package)
      end
    end

    let(:attributes) { { status: status_closed } }

    it "works and closes duplicates" do
      expect(subject)
        .to be_success

      duplicate_work_package.reload

      expect(work_package.status)
        .to eql(attributes[:status])
      expect(duplicate_work_package.status)
        .to eql(attributes[:status])
    end
  end

  describe "rescheduling work packages along follows/hierarchy relations" do
    # layout
    #                   following_parent_work_package +-follows- following2_parent_work_package   following3_parent_work_package
    #                                    |                                 |                          /                  |
    #                                hierarchy                          hierarchy                 hierarchy            hierarchy
    #                                    |                                 |                        /                    |
    #                                    +                                 +                       +                     |
    # work_package +-follows- following_work_package     following2_work_package +-follows- following3_work_package      +
    #                                                                                            following3_sibling_work_package
    let(:work_package_attributes) do
      { project_id: project.id,
        type_id: type.id,
        author_id: user.id,
        status_id: status.id,
        priority:,
        start_date: Time.zone.today,
        due_date: Time.zone.today + 5.days }
    end
    let(:attributes) do
      { start_date: Time.zone.today + 5.days,
        due_date: Time.zone.today + 10.days }
    end
    let(:following_attributes) do
      work_package_attributes.merge(parent: following_parent_work_package,
                                    subject: "following",
                                    start_date: Time.zone.today + 6.days,
                                    due_date: Time.zone.today + 20.days)
    end
    let(:following_work_package) do
      create(:work_package,
             following_attributes).tap do |wp|
        create(:follows_relation, from: wp, to: work_package)
      end
    end
    let(:following_parent_attributes) do
      work_package_attributes.merge(subject: "following_parent",
                                    start_date: Time.zone.today + 6.days,
                                    due_date: Time.zone.today + 20.days)
    end
    let(:following_parent_work_package) do
      create(:work_package,
             following_parent_attributes)
    end
    let(:following2_attributes) do
      work_package_attributes.merge(parent: following2_parent_work_package,
                                    subject: "following2",
                                    start_date: Time.zone.today + 21.days,
                                    due_date: Time.zone.today + 25.days)
    end
    let(:following2_work_package) do
      create(:work_package,
             following2_attributes)
    end
    let(:following2_parent_attributes) do
      work_package_attributes.merge(subject: "following2_parent",
                                    start_date: Time.zone.today + 21.days,
                                    due_date: Time.zone.today + 25.days)
    end
    let(:following2_parent_work_package) do
      create(:work_package,
             following2_parent_attributes).tap do |wp|
        create(:follows_relation, from: wp, to: following_parent_work_package)
      end
    end
    let(:following3_attributes) do
      work_package_attributes.merge(subject: "following3",
                                    parent: following3_parent_work_package,
                                    start_date: Time.zone.today + 26.days,
                                    due_date: Time.zone.today + 30.days)
    end
    let(:following3_work_package) do
      create(:work_package,
             following3_attributes).tap do |wp|
        create(:follows_relation, from: wp, to: following2_work_package)
      end
    end
    let(:following3_parent_attributes) do
      work_package_attributes.merge(subject: "following3_parent",
                                    start_date: Time.zone.today + 26.days,
                                    due_date: Time.zone.today + 36.days)
    end
    let(:following3_parent_work_package) do
      create(:work_package,
             following3_parent_attributes)
    end
    let(:following3_sibling_attributes) do
      work_package_attributes.merge(parent: following3_parent_work_package,
                                    subject: "following3_sibling",
                                    start_date: Time.zone.today + 32.days,
                                    due_date: Time.zone.today + 36.days)
    end
    let(:following3_sibling_work_package) do
      create(:work_package,
             following3_sibling_attributes)
    end

    before do
      work_package
      following_parent_work_package
      following_work_package
      following2_parent_work_package
      following2_work_package
      following3_parent_work_package
      following3_work_package
      following3_sibling_work_package
    end

    # rubocop:disable RSpec/ExampleLength
    # rubocop:disable RSpec/MultipleExpectations
    it "propagates the changes to start/finish date along" do
      expect(subject)
        .to be_success

      work_package.reload(select: %i(start_date due_date))
      expect(work_package.start_date)
        .to eql Time.zone.today + 5.days

      expect(work_package.due_date)
        .to eql Time.zone.today + 10.days

      following_work_package.reload(select: %i(start_date due_date))
      expect(following_work_package.start_date)
        .to eql Time.zone.today + 11.days
      expect(following_work_package.due_date)
        .to eql Time.zone.today + 25.days

      following_parent_work_package.reload(select: %i(start_date due_date))
      expect(following_parent_work_package.start_date)
        .to eql Time.zone.today + 11.days
      expect(following_parent_work_package.due_date)
        .to eql Time.zone.today + 25.days

      following2_parent_work_package.reload(select: %i(start_date due_date))
      expect(following2_parent_work_package.start_date)
        .to eql Time.zone.today + 26.days
      expect(following2_parent_work_package.due_date)
        .to eql Time.zone.today + 30.days

      following2_work_package.reload(select: %i(start_date due_date))
      expect(following2_work_package.start_date)
        .to eql Time.zone.today + 26.days
      expect(following2_work_package.due_date)
        .to eql Time.zone.today + 30.days

      following3_work_package.reload(select: %i(start_date due_date))
      expect(following3_work_package.start_date)
        .to eql Time.zone.today + 31.days
      expect(following3_work_package.due_date)
        .to eql Time.zone.today + 35.days

      following3_parent_work_package.reload(select: %i(start_date due_date))
      expect(following3_parent_work_package.start_date)
        .to eql Time.zone.today + 31.days
      expect(following3_parent_work_package.due_date)
        .to eql Time.zone.today + 36.days

      following3_sibling_work_package.reload(select: %i(start_date due_date))
      expect(following3_sibling_work_package.start_date)
        .to eql Time.zone.today + 32.days
      expect(following3_sibling_work_package.due_date)
        .to eql Time.zone.today + 36.days

      # Returns changed work packages
      expect(subject.all_results)
        .to contain_exactly(work_package, following_parent_work_package, following_work_package, following2_parent_work_package,
                            following2_work_package, following3_parent_work_package, following3_work_package)
    end
    # rubocop:enable RSpec/ExampleLength
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "rescheduling work packages with a parent having a follows relation (Regression #43220)" do
    let(:predecessor_work_package_attributes) do
      work_package_attributes.merge(
        start_date: Time.zone.today + 1.day,
        due_date: Time.zone.today + 3.days
      )
    end

    let!(:predecessor_work_package) do
      create(:work_package, predecessor_work_package_attributes).tap do |wp|
        create(:follows_relation, from: parent_work_package, to: wp)
      end
    end

    let(:parent_work_package) do
      create(:work_package, work_package_attributes)
    end

    let(:expected_parent_dates) do
      {
        start_date: Time.zone.today + 4.days,
        due_date: Time.zone.today + 4.days
      }
    end

    let(:expected_child_dates) do
      {
        start_date: Time.zone.today + 4.days,
        due_date: nil
      }
    end

    let(:attributes) { { parent: parent_work_package } }

    it "sets the parent and child dates correctly" do
      expect(subject)
        .to be_success

      expect(parent_work_package.reload.slice(:start_date, :due_date).symbolize_keys)
        .to eq(expected_parent_dates)

      expect(work_package.reload.slice(:start_date, :due_date).symbolize_keys)
        .to eq(expected_child_dates)

      expect(subject.all_results.uniq)
        .to contain_exactly(work_package, parent_work_package)
    end
  end

  describe "changing the parent" do
    let(:former_parent_attributes) do
      {
        subject: "former parent",
        project_id: project.id,
        type_id: type.id,
        author_id: user.id,
        status_id: status.id,
        priority:,
        start_date: Time.zone.today + 3.days,
        due_date: Time.zone.today + 9.days
      }
    end
    let(:attributes) { { parent: new_parent_work_package } }
    let(:former_parent_work_package) do
      create(:work_package, former_parent_attributes)
    end

    let(:former_sibling_attributes) do
      work_package_attributes.merge(
        subject: "former sibling",
        parent: former_parent_work_package,
        start_date: Time.zone.today + 3.days,
        due_date: Time.zone.today + 6.days
      )
    end
    let(:former_sibling_work_package) do
      create(:work_package, former_sibling_attributes)
    end

    let(:work_package_attributes) do
      { project_id: project.id,
        type_id: type.id,
        author_id: user.id,
        status_id: status.id,
        priority:,
        parent: former_parent_work_package,
        start_date: Time.zone.today + 7.days,
        due_date: Time.zone.today + 9.days }
    end

    let(:new_parent_attributes) do
      work_package_attributes.merge(
        subject: "new parent",
        parent: nil,
        start_date: Time.zone.today + 10.days,
        due_date: Time.zone.today + 12.days
      )
    end
    let(:new_parent_work_package) do
      create(:work_package, new_parent_attributes)
    end

    let(:new_sibling_attributes) do
      work_package_attributes.merge(
        subject: "new sibling",
        parent: new_parent_work_package,
        start_date: Time.zone.today + 10.days,
        due_date: Time.zone.today + 12.days
      )
    end
    let(:new_sibling_work_package) do
      create(:work_package, new_sibling_attributes)
    end

    before do
      work_package.reload
      former_parent_work_package.reload
      former_sibling_work_package.reload
      new_parent_work_package.reload
      new_sibling_work_package.reload
    end

    it "changes the parent reference and reschedules former and new parent" do
      expect(subject)
        .to be_success

      # sets the parent and leaves the dates unchanged
      work_package.reload
      expect(work_package.parent)
        .to eql new_parent_work_package
      expect(work_package.start_date)
        .to eql work_package_attributes[:start_date]
      expect(work_package.due_date)
        .to eql work_package_attributes[:due_date]

      # updates the former parent's dates based on the only remaining child (former sibling)
      former_parent_work_package.reload
      expect(former_parent_work_package.start_date)
        .to eql former_sibling_attributes[:start_date]
      expect(former_parent_work_package.due_date)
        .to eql former_sibling_attributes[:due_date]

      # updates the new parent's dates based on the moved work package and its now sibling
      new_parent_work_package.reload
      expect(new_parent_work_package.start_date)
        .to eql work_package_attributes[:start_date]
      expect(new_parent_work_package.due_date)
        .to eql new_sibling_attributes[:due_date]

      expect(subject.all_results.uniq)
        .to contain_exactly(work_package, former_parent_work_package, new_parent_work_package)
    end
  end

  describe "changing the parent with the parent being restricted in moving to an earlier date" do
    # there is actually some time between the new parent and its predecessor
    let(:new_parent_attributes) do
      work_package_attributes.merge(
        subject: "new parent",
        parent: nil,
        start_date: Time.zone.today + 8.days,
        due_date: Time.zone.today + 14.days
      )
    end
    let(:attributes) { { parent: new_parent_work_package } }
    let(:new_parent_work_package) do
      create(:work_package, new_parent_attributes)
    end

    let(:new_parent_predecessor_attributes) do
      work_package_attributes.merge(
        subject: "new parent predecessor",
        parent: nil,
        start_date: Time.zone.today + 1.day,
        due_date: Time.zone.today + 4.days
      )
    end
    let(:new_parent_predecessor_work_package) do
      create(:work_package, new_parent_predecessor_attributes).tap do |wp|
        create(:follows_relation, from: new_parent_work_package, to: wp)
      end
    end

    let(:work_package_attributes) do
      { project_id: project.id,
        type_id: type.id,
        author_id: user.id,
        status_id: status.id,
        priority:,
        start_date: Time.zone.today,
        due_date: Time.zone.today + 3.days }
    end

    before do
      work_package.reload
      new_parent_work_package.reload
      new_parent_predecessor_work_package.reload
    end

    it "reschedules the parent and the work package while adhering to the limitation imposed by the predecessor" do
      expect(subject)
        .to be_success

      # sets the parent and adapts the dates
      # The dates are overwritten as the new parent is unable
      # to move to the dates of its new child because of the follows relation.
      work_package.reload
      expect(work_package.parent)
        .to eql new_parent_work_package
      expect(work_package.start_date)
        .to eql new_parent_predecessor_attributes[:due_date] + 1.day
      expect(work_package.due_date)
        .to eql new_parent_predecessor_attributes[:due_date] + 4.days

      # adapts the parent's dates but adheres to its limitations
      # due to the follows relationship
      new_parent_work_package.reload
      expect(new_parent_work_package.start_date)
        .to eql new_parent_predecessor_attributes[:due_date] + 1.day
      expect(new_parent_work_package.due_date)
        .to eql new_parent_predecessor_attributes[:due_date] + 4.days

      # leaves the parent's predecessor unchanged
      new_parent_work_package.reload
      expect(new_parent_work_package.start_date)
        .to eql new_parent_predecessor_attributes[:due_date] + 1.day
      expect(new_parent_work_package.due_date)
        .to eql new_parent_predecessor_attributes[:due_date] + 4.days

      expect(subject.all_results.uniq)
        .to contain_exactly(work_package, new_parent_work_package)
    end
  end

  describe "removing the parent on a work package which precedes its sibling" do
    let(:work_package_attributes) do
      { project_id: project.id,
        type_id: type.id,
        author_id: user.id,
        status_id: status.id,
        priority:,
        parent: parent_work_package,
        start_date: Time.zone.today,
        due_date: Time.zone.today + 3.days }
    end
    let(:attributes) { { parent: nil } }

    let(:parent_attributes) do
      { project_id: project.id,
        subject: "parent",
        type_id: type.id,
        author_id: user.id,
        status_id: status.id,
        priority:,
        start_date: Time.zone.today,
        due_date: Time.zone.today + 10.days }
    end

    let(:parent_work_package) do
      create(:work_package, parent_attributes)
    end

    let(:sibling_attributes) do
      work_package_attributes.merge(
        subject: "sibling",
        start_date: Time.zone.today + 4.days,
        due_date: Time.zone.today + 10.days
      )
    end

    let(:sibling_work_package) do
      create(:work_package, sibling_attributes).tap do |wp|
        create(:follows_relation, from: wp, to: work_package)
      end
    end

    before do
      work_package.reload
      parent_work_package.reload
      sibling_work_package.reload
    end

    it "removes the parent and reschedules it" do
      expect(subject)
        .to be_success

      # work package itself is unchanged (except for the parent)
      work_package.reload
      expect(work_package.parent)
        .to be_nil
      expect(work_package.start_date)
        .to eql work_package_attributes[:start_date]
      expect(work_package.due_date)
        .to eql work_package_attributes[:due_date]

      parent_work_package.reload
      expect(parent_work_package.start_date)
        .to eql sibling_attributes[:start_date]
      expect(parent_work_package.due_date)
        .to eql sibling_attributes[:due_date]

      expect(subject.all_results.uniq)
        .to contain_exactly(work_package, parent_work_package)
    end
  end

  describe "replacing the attachments" do
    let!(:old_attachment) do
      create(:attachment, container: work_package)
    end
    let!(:other_users_attachment) do
      create(:attachment, container: nil, author: create(:user))
    end
    let!(:new_attachment) do
      create(:attachment, container: nil, author: user)
    end

    # rubocop:disable RSpec/ExampleLength
    it "reports on invalid attachments and replaces the existent with the new if everything is valid" do
      work_package.attachments.reload

      result = instance.call(attachment_ids: [other_users_attachment.id])

      expect(result)
        .to be_failure

      expect(result.errors.symbols_for(:attachments))
        .to contain_exactly(:does_not_exist)

      expect(work_package.attachments.reload)
        .to contain_exactly(old_attachment)

      expect(other_users_attachment.reload.container)
        .to be_nil

      result = instance.call(attachment_ids: [new_attachment.id])

      expect(result)
        .to be_success

      expect(work_package.attachments.reload)
        .to contain_exactly(new_attachment)

      expect(new_attachment.reload.container)
        .to eql work_package

      expect(Attachment.find_by(id: old_attachment.id))
        .to be_nil

      result = instance.call(attachment_ids: [])

      expect(result)
        .to be_success

      expect(work_package.attachments.reload)
        .to be_empty

      expect(Attachment.all)
        .to contain_exactly(other_users_attachment)
    end
    # rubocop:enable RSpec/ExampleLength
  end

  ##
  # Regression test for #27746
  # - Parent: A
  # - Child1: B
  # - Child2: C
  #
  # Trying to set parent of C to B failed because parent relation is requested before change is saved.
  describe "Changing parent to a new one that has the same parent as the current element (Regression #27746)" do
    shared_let(:admin) { create(:admin) }
    let(:user) { admin }

    let(:project) { create(:project) }
    let!(:wp_a) { create(:work_package) }
    let!(:wp_b) { create(:work_package, parent: wp_a) }
    let!(:wp_c) { create(:work_package, parent: wp_a) }

    let(:work_package) { wp_c }

    let(:attributes) { { parent: wp_b } }

    it "allows changing the parent" do
      expect(subject).to be_success
    end
  end

  describe "Changing type to one that does not have the current status (Regression #27780)" do
    let(:type) { create(:type_with_workflow) }
    let(:new_type) { create(:type) }
    let(:project_types) { [type, new_type] }
    let(:attributes) { { type: new_type } }

    context "when the work package does NOT have default status" do
      let(:status) { create(:status) }

      it "assigns the default status" do
        expect(subject).to be_success

        expect(work_package.status).to eq(Status.default)
      end
    end

    context "when the work package does have default status" do
      let(:status) { create(:default_status) }
      let!(:workflow_type) do
        create(:workflow, type: new_type, role:, old_status_id: status.id)
      end

      it "does not set the status" do
        expect(subject).to be_success

        expect(work_package)
          .not_to be_saved_change_to_status_id
      end
    end
  end

  describe "removing an invalid parent" do
    # The parent does not have a required custom field set but will need to be touched since.
    # the dates, inherited from its children (and then the only remaining child) will have to be updated.
    let!(:parent) do
      create(:work_package,
             type: project.types.first,
             project:,
             start_date: Time.zone.today - 1.day,
             due_date: Time.zone.today + 5.days)
    end
    let!(:custom_field) do
      create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |cf|
        project.types.first.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let!(:sibling) do
      create(:work_package,
             type: project.types.first,
             project:,
             parent:,
             start_date: Time.zone.today + 1.day,
             due_date: Time.zone.today + 5.days,
             custom_field.attribute_name => 5)
    end
    let!(:attributes) { { parent: nil } }

    let(:work_package_attributes) do
      {
        start_date: Time.zone.today - 1.day,
        due_date: Time.zone.today + 1.day,
        project:,
        type: project.types.first,
        parent:,
        custom_field.attribute_name => 8
      }
    end

    it "removes the parent successfully and reschedules the parent" do
      expect(subject).to be_success

      expect(work_package.reload.parent).to be_nil

      expect(parent.reload.start_date)
        .to eql(sibling.start_date)
      expect(parent.due_date)
        .to eql(sibling.due_date)
    end
  end

  describe "updating an invalid work package" do
    # The work package does not have a required custom field set.
    let(:custom_field) do
      create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |cf|
        project.types.first.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let(:attributes) { { subject: "A new subject" } }

    let(:work_package_attributes) do
      {
        subject: "The old subject",
        project:,
        type: project.types.first
      }
    end

    before do
      # Creating the custom field after the work package is already saved.
      work_package
      custom_field
    end

    it "is a failure and does not save the change" do
      expect(subject).to be_failure

      expect(work_package.reload.subject)
        .to eql work_package_attributes[:subject]
    end
  end

  describe "updating the type (custom field resetting)" do
    let(:project_types) { [type, new_type] }
    let(:new_type) { create(:type) }
    let!(:custom_field_of_current_type) do
      create(:integer_wp_custom_field, default_value: nil) do |cf|
        type.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let!(:custom_field_of_new_type) do
      create(:integer_wp_custom_field, default_value: 8) do |cf|
        new_type.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end
    let(:attributes) do
      { type: new_type }
    end

    let(:work_package_attributes) do
      {
        type:,
        project:,
        custom_field_of_current_type.attribute_name => 5
      }
    end

    it "is success, removes the existing custom field value and sets the default for the new one" do
      expect(subject).to be_success

      expect(work_package.reload.custom_values.pluck(:custom_field_id, :value))
        .to eq [[custom_field_of_new_type.id, "8"]]
    end
  end
end
