#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackages::UpdateService, 'integration tests', type: :model, with_mail: false do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) do
    %i(view_work_packages edit_work_packages add_work_packages move_work_packages manage_subtasks)
  end

  let(:status) { FactoryBot.create(:default_status) }
  let(:type) { FactoryBot.create(:type_standard) }
  let(:project_types) { [type] }
  let(:project) { FactoryBot.create(:project, types: project_types) }
  let(:priority) { FactoryBot.create(:priority) }
  let(:work_package_attributes) do
    { project_id: project.id,
      type_id: type.id,
      author_id: user.id,
      status_id: status.id,
      priority: priority }
  end
  let(:work_package) do
    FactoryBot.create(:work_package,
                      work_package_attributes)
  end
  let(:parent_work_package) do
    FactoryBot.create(:work_package,
                      work_package_attributes).tap do |w|
      w.children << work_package
      work_package.reload
    end
  end
  let(:grandparent_work_package) do
    FactoryBot.create(:work_package,
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
    FactoryBot.create(:work_package,
                      sibling1_attributes)
  end
  let(:sibling2_work_package) do
    FactoryBot.create(:work_package,
                      sibling2_attributes)
  end
  let(:child_attributes) do
    work_package_attributes.merge(parent: work_package)
  end
  let(:child_work_package) do
    FactoryBot.create(:work_package,
                      child_attributes)
  end
  let(:grandchild_attributes) do
    work_package_attributes.merge(parent: child_work_package)
  end
  let(:grandchild_work_package) do
    FactoryBot.create(:work_package,
                      grandchild_attributes)
  end
  let(:instance) do
    described_class.new(user: user,
                        model: work_package)
  end

  subject do
    instance.call(attributes.merge(send_notifications: false).symbolize_keys)
  end

  describe '#call' do
    describe 'updating subject' do
      let(:attributes) { { subject: 'New subject' } }

      it 'works' do
        expect(subject)
          .to be_success

        expect(work_package.subject)
          .to eql(attributes[:subject])
      end
    end

    describe 'updating project' do
      let(:target_project) do
        p = FactoryBot.create(:project,
                              types: target_types,
                              parent: target_parent)

        FactoryBot.create(:member,
                          user: user,
                          project: p,
                          roles: [FactoryBot.create(:role, permissions: target_permissions)])

        p
      end
      let(:attributes) { { project_id: target_project.id } }
      let(:target_permissions) { [:move_work_packages] }
      let(:target_parent) { nil }
      let(:target_types) { [type] }

      describe 'with missing permissions' do
        let(:target_permissions) { [] }

        it 'is failure' do
          expect(subject)
            .to be_failure
        end
      end

      describe 'time_entries' do
        let!(:time_entries) do
          [FactoryBot.create(:time_entry,
                             project: project,
                             work_package: work_package),
           FactoryBot.create(:time_entry,
                             project: project,
                             work_package: work_package)]
        end

        it 'moves the time entries along' do
          expect(subject)
            .to be_success

          expect(TimeEntry.where(id: time_entries.map(&:id)).pluck(:project_id).uniq)
            .to match_array [target_project.id]
        end

        describe 'categories' do
          let(:category) do
            FactoryBot.create(:category,
                              project: project)
          end

          before do
            work_package.category = category
            work_package.save!
          end

          context 'with equally named category' do
            let!(:target_category) do
              FactoryBot.create(:category,
                                name: category.name,
                                project: target_project)
            end

            it 'replaces the current category by the equally named one' do
              expect(subject)
                .to be_success

              expect(subject.result.category)
                .to eql target_category
            end
          end

          context 'w/o target category' do
            let!(:other_category) do
              FactoryBot.create(:category,
                                project: target_project)
            end

            it 'removes the category' do
              expect(subject)
                .to be_success

              expect(subject.result.category)
                .to be_nil
            end
          end
        end

        describe 'version' do
          let(:sharing) { 'none' }
          let(:version) do
            FactoryBot.create(:version,
                              status: 'open',
                              project: project,
                              sharing: sharing)
          end
          let(:work_package) do
            FactoryBot.create(:work_package,
                              version: version,
                              project: project)
          end

          context 'unshared version' do
            it 'removes the version' do
              expect(subject)
                .to be_success

              expect(subject.result.version)
                .to be_nil
            end
          end

          context 'system wide shared version' do
            let(:sharing) { 'system' }

            it 'keeps the version' do
              expect(subject)
                .to be_success

              expect(subject.result.version)
                .to eql version
            end
          end

          context 'move work package in project hierarchy' do
            let(:target_parent) do
              project
            end

            context 'unshared version' do
              it 'removes the version' do
                expect(subject)
                  .to be_success

                expect(subject.result.version)
                  .to be_nil
              end
            end

            context 'shared version' do
              let(:sharing) { 'tree' }

              it 'keeps the version' do
                expect(subject)
                  .to be_success

                expect(subject.result.version)
                  .to eql version
              end
            end
          end
        end

        describe 'type' do
          let(:target_types) { [type, other_type] }
          let(:other_type) { FactoryBot.create(:type) }
          let(:default_type) { type }
          let(:project_types) { [type, other_type] }
          let!(:workflow_type) do
            FactoryBot.create(:workflow, type: default_type, role: role, old_status_id: status.id)
          end
          let!(:workflow_other_type) do
            FactoryBot.create(:workflow, type: other_type, role: role, old_status_id: status.id)
          end

          context 'with the type existing in the target project' do
            it 'keeps the type' do
              expect(subject)
                .to be_success

              expect(subject.result.type)
                .to eql type
            end
          end

          context 'with a default type existing in the target project' do
            let(:target_types) { [other_type, default_type] }

            it 'uses the default type' do
              expect(subject)
                .to be_success

              expect(subject.result.type)
                .to eql default_type
            end
          end

          context 'with only non default types' do
            let(:target_types) { [other_type] }

            it 'uses the first type' do
              expect(subject)
                .to be_success

              expect(subject.result.type)
                .to eql other_type
            end
          end

          context 'with an invalid type being provided' do
            let(:target_types) { [type] }

            let(:attributes) do
              { project: target_project,
                type: other_type }
            end

            it 'is unsuccessful' do
              expect(subject)
                .to be_failure
            end
          end
        end
      end
    end

    describe 'inheriting dates' do
      let(:attributes) { { start_date: Date.today - 8.days, due_date: Date.today + 12.days } }
      let(:sibling1_attributes) do
        work_package_attributes.merge(start_date: Date.today - 5.days,
                                      due_date: Date.today + 10.days,
                                      parent: parent_work_package)
      end
      let(:sibling2_attributes) do
        work_package_attributes.merge(due_date: Date.today + 16.days,
                                      parent: parent_work_package)
      end

      before do
        parent_work_package
        grandparent_work_package
        sibling1_work_package
        sibling2_work_package
      end

      it 'works and inherits' do
        expect(subject)
          .to be_success

        # receives the provided start/finish date
        expect(work_package.start_date)
          .to eql(attributes[:start_date])
        expect(work_package.due_date)
          .to eql(attributes[:due_date])

        # receives the min/max of the children's start/finish date
        [parent_work_package,
         grandparent_work_package].each do |wp|
          wp.reload

          expect(wp.start_date)
            .to eql(attributes[:start_date])
          expect(wp.due_date)
            .to eql(sibling2_work_package.due_date)
        end

        # sibling dates are unchanged
        sibling1_work_package.reload
        expect(sibling1_work_package.start_date)
          .to eql(sibling1_attributes[:start_date])
        expect(sibling1_work_package.due_date)
          .to eql(sibling1_attributes[:due_date])

        sibling2_work_package.reload
        expect(sibling2_work_package.start_date)
          .to eql(sibling2_attributes[:start_date])
        expect(sibling2_work_package.due_date)
          .to eql(sibling2_attributes[:due_date])
      end
    end

    describe 'inheriting done_ratio' do
      let(:attributes) { { done_ratio: 50 } }
      let(:work_package_attributes) do
        { project_id: project.id,
          type_id: type.id,
          author_id: user.id,
          status_id: status.id,
          priority: priority,
          estimated_hours: 10 }
      end

      let(:sibling1_attributes) do
        work_package_attributes.merge(estimated_hours: nil,
                                      done_ratio: 20,
                                      parent: parent_work_package)
      end
      let(:sibling2_attributes) do
        work_package_attributes.merge(done_ratio: 0,
                                      estimated_hours: 100,
                                      parent: parent_work_package)
      end

      before do
        parent_work_package
        grandparent_work_package
        sibling1_work_package
        sibling2_work_package
      end

      it 'works and inherits average done ratio of leaves weighted by estimated times' do
        expect(subject)
          .to be_success

        # set to the provided values
        expect(work_package.done_ratio)
          .to eql(attributes[:done_ratio])

        # calculated
        # sibling1 not factored in as its estimated_hours are nil
        calculated_ratio = (work_package.done_ratio * work_package.estimated_hours +
                            sibling2_work_package.done_ratio * sibling2_work_package.estimated_hours) /
                           (work_package.done_ratio +
                            sibling2_work_package.done_ratio)

        [parent_work_package,
         grandparent_work_package].each do |wp|
          wp.reload

          expect(wp.done_ratio)
            .to eql(calculated_ratio.to_i)
        end

        # unchanged
        sibling1_work_package.reload
        expect(sibling1_work_package.done_ratio)
          .to eql(sibling1_attributes[:done_ratio])

        sibling2_work_package.reload
        expect(sibling2_work_package.done_ratio)
          .to eql(sibling2_attributes[:done_ratio])
      end
    end

    describe 'inheriting estimated_hours' do
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

      it 'works and inherits' do
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

          expect(wp.estimated_hours).to eql(nil)
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
      end
    end

    describe 'closing duplicates on closing status' do
      let(:status_closed) do
        FactoryBot.create(:status,
                          is_closed: true).tap do |status_closed|
          FactoryBot.create(:workflow,
                            old_status: status,
                            new_status: status_closed,
                            type: type,
                            role: role)
        end
      end
      let(:duplicate_work_package) do
        FactoryBot.create(:work_package,
                          work_package_attributes).tap do |wp|
          wp.duplicated << work_package
        end
      end

      let(:attributes) { { status: status_closed } }

      before do
        duplicate_work_package
      end

      it 'works and closes duplicates' do
        expect(subject)
          .to be_success

        duplicate_work_package.reload

        expect(work_package.status)
          .to eql(attributes[:status])
        expect(duplicate_work_package.status)
          .to eql(attributes[:status])
      end
    end

    describe 'rescheduling work packages along follows/hierarchy relations' do
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
          priority: priority,
          start_date: Date.today,
          due_date: Date.today + 5.days }
      end
      let(:following_attributes) do
        work_package_attributes.merge(parent: following_parent_work_package,
                                      subject: 'following',
                                      start_date: Date.today + 6.days,
                                      due_date: Date.today + 20.days)
      end
      let(:following_work_package) do
        FactoryBot.create(:work_package,
                          following_attributes).tap do |wp|
          wp.follows << work_package
        end
      end
      let(:following_parent_attributes) do
        work_package_attributes.merge(subject: 'following_parent',
                                      start_date: Date.today + 6.days,
                                      due_date: Date.today + 20.days)
      end
      let(:following_parent_work_package) do
        FactoryBot.create(:work_package,
                          following_parent_attributes)
      end
      let(:following2_attributes) do
        work_package_attributes.merge(parent: following2_parent_work_package,
                                      subject: 'following2',
                                      start_date: Date.today + 21.days,
                                      due_date: Date.today + 25.days)
      end
      let(:following2_work_package) do
        FactoryBot.create(:work_package,
                          following2_attributes)
      end
      let(:following2_parent_attributes) do
        work_package_attributes.merge(subject: 'following2_parent',
                                      start_date: Date.today + 21.days,
                                      due_date: Date.today + 25.days)
      end
      let(:following2_parent_work_package) do
        FactoryBot.create(:work_package,
                          following2_parent_attributes).tap do |wp|
          wp.follows << following_parent_work_package
        end
      end
      let(:following3_attributes) do
        work_package_attributes.merge(subject: 'following3',
                                      parent: following3_parent_work_package,
                                      start_date: Date.today + 26.days,
                                      due_date: Date.today + 30.days)
      end
      let(:following3_work_package) do
        FactoryBot.create(:work_package,
                          following3_attributes).tap do |wp|
          wp.follows << following2_work_package
        end
      end
      let(:following3_parent_attributes) do
        work_package_attributes.merge(subject: 'following3_parent',
                                      start_date: Date.today + 26.days,
                                      due_date: Date.today + 36.days)
      end
      let(:following3_parent_work_package) do
        FactoryBot.create(:work_package,
                          following3_parent_attributes)
      end
      let(:following3_sibling_attributes) do
        work_package_attributes.merge(parent: following3_parent_work_package,
                                      subject: 'following3_sibling',
                                      start_date: Date.today + 32.days,
                                      due_date: Date.today + 36.days)
      end
      let(:following3_sibling_work_package) do
        FactoryBot.create(:work_package,
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

      let(:attributes) do
        { start_date: Date.today + 5.days,
          due_date: Date.today + 10.days }
      end

      it 'propagates the changes to start/finish date along' do
        expect(subject)
          .to be_success

        work_package.reload(select: %i(start_date due_date))
        expect(work_package.start_date)
          .to eql Date.today + 5.days

        expect(work_package.due_date)
          .to eql Date.today + 10.days

        following_work_package.reload(select: %i(start_date due_date))
        expect(following_work_package.start_date)
          .to eql Date.today + 11.days

        expect(following_work_package.due_date)
          .to eql Date.today + 25.days

        following_parent_work_package.reload(select: %i(start_date due_date))
        expect(following_parent_work_package.start_date)
          .to eql Date.today + 11.days

        expect(following_parent_work_package.due_date)
          .to eql Date.today + 25.days

        following2_parent_work_package.reload(select: %i(start_date due_date))
        expect(following2_parent_work_package.start_date)
          .to eql Date.today + 26.days

        expect(following2_parent_work_package.due_date)
          .to eql Date.today + 30.days

        following2_work_package.reload(select: %i(start_date due_date))
        expect(following2_work_package.start_date)
          .to eql Date.today + 26.days

        expect(following2_work_package.due_date)
          .to eql Date.today + 30.days

        following3_work_package.reload(select: %i(start_date due_date))
        expect(following3_work_package.start_date)
          .to eql Date.today + 31.days

        expect(following3_work_package.due_date)
          .to eql Date.today + 35.days

        following3_parent_work_package.reload(select: %i(start_date due_date))
        expect(following3_parent_work_package.start_date)
          .to eql Date.today + 31.days

        expect(following3_parent_work_package.due_date)
          .to eql Date.today + 36.days

        following3_sibling_work_package.reload(select: %i(start_date due_date))
        expect(following3_sibling_work_package.start_date)
          .to eql Date.today + 32.days

        expect(following3_sibling_work_package.due_date)
          .to eql Date.today + 36.days
      end
    end

    describe 'rescheduling work packages forward follows/hierarchy relations' do
      # layout
      #                                                              other_work_package
      #                                                                      +
      #                                                                      |
      #                                                                   follows (delay: 3 days)
      #                                                                      |
      #                   following_parent_work_package +-follows- following2_parent_work_package
      #                                    |                                 |
      #                                hierarchy                          hierarchy
      #                                    |                                 |
      #                                    +                                 +
      # work_package +-follows- following_work_package             following2_work_package +-follows- following3_work_package
      let(:work_package_attributes) do
        { project_id: project.id,
          type_id: type.id,
          author_id: user.id,
          status_id: status.id,
          priority: priority,
          start_date: Date.today,
          due_date: Date.today + 5.days }
      end
      let(:following_attributes) do
        work_package_attributes.merge(parent: following_parent_work_package,
                                      subject: 'following',
                                      start_date: Date.today + 6.days,
                                      due_date: Date.today + 20.days)
      end
      let(:following_work_package) do
        FactoryBot.create(:work_package,
                          following_attributes).tap do |wp|
          wp.follows << work_package
        end
      end
      let(:following_parent_attributes) do
        work_package_attributes.merge(subject: 'following_parent',
                                      start_date: Date.today + 6.days,
                                      due_date: Date.today + 20.days)
      end
      let(:following_parent_work_package) do
        FactoryBot.create(:work_package,
                          following_parent_attributes)
      end
      let(:other_attributes) do
        work_package_attributes.merge(subject: 'other',
                                      start_date: Date.today + 10.days,
                                      due_date: Date.today + 18.days)
      end
      let(:other_work_package) do
        FactoryBot.create(:work_package,
                          other_attributes)
      end
      let(:following2_attributes) do
        work_package_attributes.merge(parent: following2_parent_work_package,
                                      subject: 'following2',
                                      start_date: Date.today + 24.days,
                                      due_date: Date.today + 28.days)
      end
      let(:following2_work_package) do
        FactoryBot.create(:work_package,
                          following2_attributes)
      end
      let(:following2_parent_attributes) do
        work_package_attributes.merge(subject: 'following2_parent',
                                      start_date: Date.today + 24.days,
                                      due_date: Date.today + 28.days)
      end
      let(:following2_parent_work_package) do
        following2 = FactoryBot.create(:work_package,
                                       following2_parent_attributes).tap do |wp|
          wp.follows << following_parent_work_package
        end

        FactoryBot.create(:relation,
                          relation_type: Relation::TYPE_FOLLOWS,
                          from: following2,
                          to: other_work_package,
                          delay: 3)

        following2
      end
      let(:following3_attributes) do
        work_package_attributes.merge(subject: 'following3',
                                      start_date: Date.today + 29.days,
                                      due_date: Date.today + 33.days)
      end
      let(:following3_work_package) do
        FactoryBot.create(:work_package,
                          following3_attributes).tap do |wp|
          wp.follows << following2_work_package
        end
      end

      before do
        work_package
        other_work_package
        following_parent_work_package
        following_work_package
        following2_parent_work_package
        following2_work_package
        following3_work_package
      end

      let(:attributes) do
        { start_date: Date.today - 5.days,
          due_date: Date.today }
      end

      it 'propagates the changes to start/finish date along' do
        expect(subject)
          .to be_success

        work_package.reload(select: %i(start_date due_date))
        expect(work_package.start_date)
          .to eql Date.today - 5.days

        expect(work_package.due_date)
          .to eql Date.today

        following_work_package.reload(select: %i(start_date due_date))
        expect(following_work_package.start_date)
          .to eql Date.today + 1.day

        expect(following_work_package.due_date)
          .to eql Date.today + 15.days

        following_parent_work_package.reload(select: %i(start_date due_date))
        expect(following_parent_work_package.start_date)
          .to eql Date.today + 1.days

        expect(following_parent_work_package.due_date)
          .to eql Date.today + 15.days

        following2_parent_work_package.reload(select: %i(start_date due_date))
        expect(following2_parent_work_package.start_date)
          .to eql Date.today + 22.days

        expect(following2_parent_work_package.due_date)
          .to eql Date.today + 26.days

        following2_work_package.reload(select: %i(start_date due_date))
        expect(following2_work_package.start_date)
          .to eql Date.today + 22.days

        expect(following2_work_package.due_date)
          .to eql Date.today + 26.days

        following3_work_package.reload(select: %i(start_date due_date))
        expect(following3_work_package.start_date)
          .to eql Date.today + 27.days

        expect(following3_work_package.due_date)
          .to eql Date.today + 31.days
      end
    end

    describe 'changing the parent' do
      let(:former_parent_attributes) do
        {
          subject: 'former parent',
          project_id: project.id,
          type_id: type.id,
          author_id: user.id,
          status_id: status.id,
          priority: priority,
          start_date: Date.today + 3.days,
          due_date: Date.today + 9.days
        }
      end
      let(:former_parent_work_package) do
        FactoryBot.create(:work_package, former_parent_attributes)
      end

      let(:former_sibling_attributes) do
        work_package_attributes.merge(
          subject: 'former sibling',
          parent: former_parent_work_package,
          start_date: Date.today + 3.days,
          due_date: Date.today + 6.days
        )
      end
      let(:former_sibling_work_package) do
        FactoryBot.create(:work_package, former_sibling_attributes)
      end

      let(:work_package_attributes) do
        { project_id: project.id,
          type_id: type.id,
          author_id: user.id,
          status_id: status.id,
          priority: priority,
          parent: former_parent_work_package,
          start_date: Date.today + 7.days,
          due_date: Date.today + 9.days }
      end

      let(:new_parent_attributes) do
        work_package_attributes.merge(
          subject: 'new parent',
          parent: nil,
          start_date: Date.today + 10.days,
          due_date: Date.today + 12.days
        )
      end
      let(:new_parent_work_package) do
        FactoryBot.create(:work_package, new_parent_attributes)
      end

      let(:new_sibling_attributes) do
        work_package_attributes.merge(
          subject: 'new sibling',
          parent: new_parent_work_package,
          start_date: Date.today + 10.days,
          due_date: Date.today + 12.days
        )
      end
      let(:new_sibling_work_package) do
        FactoryBot.create(:work_package, new_sibling_attributes)
      end

      before do
        work_package.reload
        former_parent_work_package.reload
        former_sibling_work_package.reload
        new_parent_work_package.reload
        new_sibling_work_package.reload
      end

      let(:attributes) { { parent: new_parent_work_package } }

      it 'changes the parent reference and reschedules former and new parent' do
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

        # updates the former parent's dates
        former_parent_work_package.reload
        expect(former_parent_work_package.start_date)
          .to eql former_sibling_attributes[:start_date]
        expect(former_parent_work_package.due_date)
          .to eql former_sibling_attributes[:due_date]

        # updates the new parent's dates
        new_parent_work_package.reload
        expect(new_parent_work_package.start_date)
          .to eql work_package_attributes[:start_date]
        expect(new_parent_work_package.due_date)
          .to eql new_sibling_attributes[:due_date]
      end
    end

    describe 'changing the parent with the parent being restricted in moving to an earlier date' do
      # there is actually some time between the new parent and its predecessor
      let(:new_parent_attributes) do
        work_package_attributes.merge(
          subject: 'new parent',
          parent: nil,
          start_date: Date.today + 8.days,
          due_date: Date.today + 14.days
        )
      end
      let(:new_parent_work_package) do
        FactoryBot.create(:work_package, new_parent_attributes)
      end

      let(:new_parent_predecessor_attributes) do
        work_package_attributes.merge(
          subject: 'new parent predecessor',
          parent: nil,
          start_date: Date.today + 1.day,
          due_date: Date.today + 4.days
        )
      end
      let(:new_parent_predecessor_work_package) do
        wp = FactoryBot.create(:work_package, new_parent_predecessor_attributes)

        wp.precedes << new_parent_work_package

        wp
      end

      let(:work_package_attributes) do
        { project_id: project.id,
          type_id: type.id,
          author_id: user.id,
          status_id: status.id,
          priority: priority,
          start_date: Date.today,
          due_date: Date.today + 3.days }
      end

      before do
        work_package.reload
        new_parent_work_package.reload
        new_parent_predecessor_work_package.reload
      end

      let(:attributes) { { parent: new_parent_work_package } }

      it 'reschedules the parent and the work package while adhering to the limitation imposed by the predecessor' do
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
      end
    end

    describe 'removing the parent on a work package which precedes its sibling' do
      let(:work_package_attributes) do
        { project_id: project.id,
          type_id: type.id,
          author_id: user.id,
          status_id: status.id,
          priority: priority,
          parent: parent_work_package,
          start_date: Date.today,
          due_date: Date.today + 3.days }
      end

      let(:parent_attributes) do
        { project_id: project.id,
          subject: 'parent',
          type_id: type.id,
          author_id: user.id,
          status_id: status.id,
          priority: priority,
          start_date: Date.today,
          due_date: Date.today + 10.days }
      end

      let(:parent_work_package) do
        FactoryBot.create(:work_package, parent_attributes)
      end

      let(:sibling_attributes) do
        work_package_attributes.merge(
          subject: 'sibling',
          start_date: Date.today + 4.days,
          due_date: Date.today + 10.days
        )
      end

      let(:sibling_work_package) do
        wp = FactoryBot.create(:work_package, sibling_attributes)

        wp.follows << work_package

        wp
      end

      before do
        work_package.reload
        parent_work_package.reload
        sibling_work_package.reload
      end

      let(:attributes) { { parent: nil } }

      it 'removes the parent and reschedules it' do
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
      end
    end

    describe 'replacing the attachments' do
      let!(:old_attachment) do
        FactoryBot.create(:attachment, container: work_package)
      end
      let!(:other_users_attachment) do
        FactoryBot.create(:attachment, container: nil, author: FactoryBot.create(:user))
      end
      let!(:new_attachment) do
        FactoryBot.create(:attachment, container: nil, author: user)
      end

      it 'reports on invalid attachments and replaces the existent with the new if everything is valid' do
        work_package.attachments.reload

        result = instance.call(attachment_ids: [other_users_attachment.id])

        expect(result)
          .to be_failure

        expect(result.errors.symbols_for(:attachments))
          .to match_array [:does_not_exist]

        expect(work_package.attachments.reload)
          .to match_array [old_attachment]

        expect(other_users_attachment.reload.container)
          .to be_nil

        result = instance.call(attachment_ids: [new_attachment.id])

        expect(result)
          .to be_success

        expect(work_package.attachments.reload)
          .to match_array [new_attachment]

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
          .to match_array [other_users_attachment]
      end
    end
  end

  ##
  # Regression test for #27746
  # - Parent: A
  # - Child1: B
  # - Child2: C
  #
  # Trying to set parent of C to B failed because parent relation is requested before change is saved.
  describe 'Changing parent to a new one that has the same parent as the current element (Regression #27746)' do
    using_shared_fixtures :admin
    let(:user) { admin }

    let(:project) { FactoryBot.create :project }
    let!(:wp_a) { FactoryBot.create :work_package }
    let!(:wp_b) { FactoryBot.create :work_package, parent: wp_a }
    let!(:wp_c) { FactoryBot.create :work_package, parent: wp_a }

    let(:work_package) { wp_c }

    let(:attributes) { { parent: wp_b } }

    it 'allows changing the parent' do
      expect(subject).to be_success
    end
  end

  describe 'Changing type to one that does not have the current status (Regression #27780)' do
    let(:type) { FactoryBot.create :type_with_workflow }
    let(:new_type) { FactoryBot.create :type }
    let(:project_types) { [type, new_type] }
    let(:attributes) { { type: new_type } }

    context 'work package does NOT have default status' do
      let(:status) { FactoryBot.create(:status) }

      it 'assigns the default status' do
        expect(work_package).to receive(:status=).and_call_original
        expect(subject).to be_success

        expect(work_package.status).to eq(Status.default)
      end
    end

    context 'work package does have default status' do
      let(:status) { FactoryBot.create :default_status }
      let!(:workflow_type) do
        FactoryBot.create(:workflow, type: new_type, role: role, old_status_id: status.id)
      end

      it 'does not set the status' do
        expect(work_package).not_to receive(:status=)
        expect(subject).to be_success
      end
    end
  end
end
