#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackages::MovesController, type: :controller do

  let(:user) { FactoryGirl.create(:user) }
  let(:role) {
    FactoryGirl.create :role,
                       permissions: [:move_work_packages]
  }
  let(:type) { FactoryGirl.create :type }
  let(:type_2) { FactoryGirl.create :type }
  let(:status) { FactoryGirl.create :default_status }
  let(:target_status) { FactoryGirl.create :status }
  let(:priority) { FactoryGirl.create :priority }
  let(:target_priority) { FactoryGirl.create :priority }
  let(:project) {
    FactoryGirl.create(:project,
                       is_public: false,
                       types: [type, type_2])
  }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project_id: project.id,
                       type: type,
                       author: user,
                       priority: priority)
  }

  let(:current_user) { FactoryGirl.create(:user) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'new.html' do
    become_admin

    describe 'w/o a valid planning element id' do

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 404 page' do
          get 'new', id: '1337'

          expect(response.response_code).to be === 404
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_view_planning_element_permissions

        it 'raises ActiveRecord::RecordNotFound errors' do
          get 'new', id: '1337'

          expect(response.response_code).to be === 404
        end
      end
    end

    describe 'w/ a valid planning element id' do
      become_admin

      describe 'w/o being a member or administrator' do
        become_non_member

        it 'renders a 403 Forbidden page' do
          get 'new', work_package_id: work_package.id

          expect(response.response_code).to eq(403)
        end
      end

      describe 'w/ the current user being a member' do
        become_member_with_move_work_package_permissions

        before do
          get 'new', work_package_id: work_package.id
        end

        it 'renders the new builder template' do
          expect(response).to render_template('work_packages/moves/new', formats: ['html'], layout: :base)
        end
      end
    end
  end

  describe '#create' do
    become_member_with_move_work_package_permissions

    let!(:member) { FactoryGirl.create(:member, user: current_user, project: target_project, roles: [role]) }
    let(:target_project) { FactoryGirl.create(:project, is_public: false) }
    let(:work_package_2) {
      FactoryGirl.create(:work_package,
                         project_id: project.id,
                         type: type_2,
                         priority: priority)
    }

    describe 'an issue to another project' do
      context 'w/o following' do
        subject do
          post :create,
               work_package_id: work_package.id,
               new_project_id: target_project.id,
               type_id: '',
               author_id: user.id,
               assigned_to_id: '',
               responsible_id: '',
               status_id: '',
               start_date: '',
               due_date: ''
        end

        it "redirects to the project's work packages page" do
          is_expected.to be_redirect
          is_expected.to redirect_to(project_work_packages_path(project))
        end
      end

      context 'with following' do
        subject do
          post :create,
               work_package_id: work_package.id,
               new_project_id: target_project.id,
               new_type_id: target_project.types.first.id, # FIXME (see #1868) the validation on the work_package requires a proper target-type, other cases are not tested here
               assigned_to_id: '',
               responsible_id: '',
               status_id: '',
               start_date: '',
               due_date: '',
               follow: '1'
        end

        it 'redirects to the work package page' do
          is_expected.to be_redirect
          is_expected.to redirect_to(work_package_path(work_package))
        end
      end
    end

    describe 'bulk move' do
      context 'with two work packages' do
        before do
          # make sure, that the types of the work-packages are available on the target-project
          # (and handle it/test it, when this is not the case see #1868)
          target_project.types << [work_package.type, work_package_2.type]
          target_project.save

          post :create,
               ids: [work_package.id, work_package_2.id],
               new_project_id: target_project.id

          work_package.reload
          work_package_2.reload
        end

        it 'project id is changed for both work packages' do
          expect(work_package.project_id).to eq(target_project.id)
          expect(work_package_2.project_id).to eq(target_project.id)
        end

        it 'changed no types' do
          expect(work_package.type_id).to eq(type.id)
          expect(work_package_2.type_id).to eq(type_2.id)
        end
      end

      context 'to another type' do
        before do
          post :create,
               ids: [work_package.id, work_package_2.id],
               new_type_id: type_2.id

          work_package.reload
          work_package_2.reload
        end

        it "changed work packages' types" do
          expect(work_package.type_id).to eq(type_2.id)
          expect(work_package_2.type_id).to eq(type_2.id)
        end
      end

      context 'with another priority' do
        before do
          post :create,
               ids: [work_package.id, work_package_2.id],
               priority_id: target_priority.id

          work_package.reload
          work_package_2.reload
        end

        it "changed work packages' priority" do
          expect(work_package.priority_id).to eq(target_priority.id)
          expect(work_package_2.priority_id).to eq(target_priority.id)
        end
      end

      shared_examples_for 'single note for moved work package' do
        it { expect(moved_work_package.journals.count).to eq(2) }

        it { expect(moved_work_package.journals.sort_by(&:id).last.notes).to eq(note) }
      end

      describe 'move with given note' do
        let(:note) { 'Moving a work package' }

        context 'w/o work package changes' do
          before do
            post :create,
                 ids: [work_package.id],
                 notes: note
          end

          it_behaves_like 'single note for moved work package' do
            let(:moved_work_package) { work_package.reload }
          end
        end

        context 'w/o work package changes' do
          before do
            post :create,
                 ids: [work_package.id],
                 notes: note,
                 priority_id: target_priority.id
          end

          it_behaves_like 'single note for moved work package' do
            let(:moved_work_package) { work_package.reload }
          end
        end

      end

      describe '&copy' do
        context 'follows to another project' do
          before do
            post :create,
                 ids: [work_package.id],
                 copy: '',
                 new_project_id: target_project.id,
                 new_type_id: target_project.types.first.id, # FIXME see #1868
                 follow: ''
          end

          it 'redirects to the work package copy' do
            copy = WorkPackage.first(order: 'id desc')
            is_expected.to redirect_to(work_package_path(copy))
          end
        end

        context "w/o changing the work package's attribute" do
          before do
            post :create,
                 ids: [work_package.id],
                 copy: '',
                 new_project_id: target_project.id
          end

          subject { WorkPackage.first(order: 'id desc', conditions: { project_id: project.id }) }

          it 'did not change the type' do
            expect(subject.type_id).to eq(work_package.type_id)
          end

          it 'did not change the status' do
            expect(subject.status_id).to eq(work_package.status_id)
          end

          it 'did not change the assignee' do
            expect(subject.assigned_to_id).to eq(work_package.assigned_to_id)
          end

          it 'did not change the responsible' do
            expect(subject.responsible_id).to eq(work_package.responsible_id)
          end
        end

        context "with changing the work package's attribute" do
          let(:start_date) { Date.today }
          let(:due_date) { Date.today + 1 }
          let(:target_user) { FactoryGirl.create :user }

          before do
            post :create,
                 ids: [work_package.id, work_package_2.id],
                 copy: '',
                 new_project_id: target_project.id,
                 new_type_id: target_project.types.first.id, # FIXME see #1868
                 assigned_to_id: target_user.id,
                 responsible_id: target_user.id,
                 status_id: target_status,
                 start_date: start_date,
                 due_date: due_date
          end

          subject { WorkPackage.all(limit: 2, order: 'id desc', conditions: { project_id: target_project.id }) }

          it 'copied two work packages' do
            expect(subject.count).to eq(2)
          end

          it 'did change the project' do
            subject.map(&:project_id).each do |id|
              expect(id).to eq(target_project.id)
            end
          end

          it 'did change the assignee' do
            subject.map(&:assigned_to_id).each do |id|
              expect(id).to eq(target_user.id)
            end
          end

          it 'did change the responsible' do
            subject.map(&:responsible_id).each do |id|
              expect(id).to eq(target_user.id)
            end
          end

          it 'did change the status' do
            subject.map(&:status_id).each do |id|
              expect(id).to eq(target_status.id)
            end
          end

          it 'did change the start date' do
            subject.map(&:start_date).each do |date|
              expect(date).to eq(start_date)
            end
          end

          it 'did change the end date' do
            subject.map(&:due_date).each do |date|
              expect(date).to eq(due_date)
            end
          end
        end

        context 'with given note' do
          let(:note) { 'Copying a work package' }

          before do
            post :create,
                 ids: [work_package.id],
                 copy: '',
                 notes: note
          end

          subject { WorkPackage.all(limit: 1, order: 'id desc').last.journals }

          it { expect(subject.count).to eq(2) }

          it { expect(subject.sort_by(&:id).last.notes).to eq(note) }
        end

        context 'child work package from one project to other' do
          let(:to_project) {
            FactoryGirl.create(:project,
                               types: [type])
          }
          let!(:member) {
            FactoryGirl.create(:member,
                               user: current_user,
                               roles: [role],
                               project: to_project)
          }
          let(:child_wp) {
            FactoryGirl.create(:work_package,
                               type: type,
                               project: project,
                               parent_id: work_package.id)
          }

          shared_examples_for 'successful move' do
            it { expect(flash[:notice]).to eq(I18n.t(:notice_successful_create)) }
          end

          before do
            allow(User).to receive(:current).and_return(current_user)

            def self.copy_child_work_package
              post :create,
                   ids: [child_wp.id],
                   copy: '',
                   new_project_id: to_project.id,
                   work_package_id: child_wp.id,
                   new_type_id: to_project.types.first.id
            end
          end

          context 'when cross_project_work_package_relations is disabled' do
            before do
              allow(Setting).to receive(:cross_project_work_package_relations?).and_return(false)

              copy_child_work_package
            end

            it_behaves_like 'successful move'

            it { expect(to_project.work_packages.first.parent_id).to be_nil }
          end

          context 'when cross_project_work_package_relations is enabled' do
            before do
              allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)

              copy_child_work_package
            end

            it_behaves_like 'successful move'

            it { expect(to_project.work_packages.first.parent_id).to eq(child_wp.parent_id) }
          end
        end
      end
    end
  end
end
