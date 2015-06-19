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

# TODO: this spec is for now targeting each WorkPackage subclass
# independently. Once only WorkPackage exist, this can safely be consolidated.
describe WorkPackage, '#reschedule_after', type: :model do
  let(:project) { FactoryGirl.build(:project_with_types) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project, type: project.types.first) }
  let(:work_package2) { FactoryGirl.create(:work_package, project: project, type: project.types.first) }
  let(:work_package3) { FactoryGirl.create(:work_package, project: project, type: project.types.first) }

  [:work_package].each do |subclass|

    describe "for a #{subclass}" do
      let(:instance) { send(subclass) }
      let(:child) do
        child = send(:"#{subclass}2")
        child.parent_id = instance.id

        child
      end
      let(:grandchild) do
        gchild = send(:"#{subclass}3")
        gchild.parent_id = child.id

        gchild
      end

      describe 'for a single node having start and due date' do
        before do
          instance.start_date = Date.today
          instance.due_date = Date.today + 7.days

          instance.reschedule_after(Date.today + 3.days)
        end

        it 'should set the start_date to the provided date' do
          expect(instance.start_date).to eq(Date.today + 3.days)
        end

        it 'should set the set the due date plus the duration' do
          expect(instance.due_date).to eq(Date.today + 10.days)
        end
      end

      describe 'for a single node having neither start nor due date' do
        before do
          instance.start_date = nil
          instance.due_date = nil

          instance.reschedule_after(Date.today + 3.days)
        end

        it 'should set the start_date to the provided date' do
          expect(instance.start_date).to eq(Date.today + 3.days)
        end

        it 'should set the set the due date plus the duration' do
          expect(instance.due_date).to eq(Date.today + 3.days)
        end
      end

      describe 'for a single node having only a due date' do
        before do
          instance.start_date = nil
          instance.due_date = Date.today + 7.days

          instance.reschedule_after(Date.today + 3.days)
        end

        it 'should set the start_date to the provided date' do
          expect(instance.start_date).to eq(Date.today + 3.days)
        end

        it 'should set the set the due date plus the duration' do
          expect(instance.due_date).to eq(Date.today + 3.days)
        end
      end

      describe 'with a child' do
        before do
          child.start_date = Date.today
          child.due_date = Date.today + 7.days
          child.save!
          instance.reload

          instance.reschedule_after(Date.today + 3.days)
        end

        it 'should set the start_date to the provided date' do
          instance.reload
          expect(instance.start_date).to eq(Date.today + 3.days)
        end

        it "should set the set the due date to the provided date plus the child's duration" do
          instance.reload
          expect(instance.due_date).to eq(Date.today + 10.days)
        end

        it "should set the child's start date to the provided date" do
          child.reload
          expect(child.start_date).to eq(Date.today + 3.days)
        end

        it "should set the set child's due date to the provided date plus the child's duration" do
          child.reload
          expect(child.due_date).to eq(Date.today + 10.days)
        end
      end

      describe "with a child
                while the new date is set to be between the child's start and due date" do
        before do
          child.start_date = Date.today + 1.day
          child.due_date = Date.today + 7.days

          child.save!
          instance.reload

          instance.start_date = Date.today
          instance.due_date = Date.today + 7.days

          instance.reschedule_after(Date.today + 3.days)
        end

        it 'should set the start_date to the provided date' do
          instance.reload
          expect(instance.start_date).to eq(Date.today + 3.days)
        end

        it "should set the set the due date to the provided date plus the child's duration" do
          instance.reload
          expect(instance.due_date).to eq(Date.today + 9.days)
        end

        it "should set the child's start date to the provided date" do
          child.reload
          expect(child.start_date).to eq(Date.today + 3.days)
        end

        it "should set the set child's due date to the provided date plus the child's duration" do
          child.reload
          expect(child.due_date).to eq(Date.today + 9.days)
        end
      end

      describe 'with child and grandchild' do

        before do
          child.save
          grandchild.start_date = Date.today
          grandchild.due_date = Date.today + 7.days

          grandchild.save!
          instance.reload

          instance.reschedule_after(Date.today + 3.days)
        end

        it 'should set the start_date to the provided date' do
          instance.reload
          expect(instance.start_date).to eq(Date.today + 3.days)
        end

        it "should set the set the due date to the provided date plus the child's duration" do
          instance.reload
          expect(instance.due_date).to eq(Date.today + 10.days)
        end

        it "should set the child's start date to the provided date" do
          child.reload
          expect(child.start_date).to eq(Date.today + 3.days)
        end

        it "should set the set child's due date to the provided date plus the grandchild's duration" do
          child.reload
          expect(child.due_date).to eq(Date.today + 10.days)
        end

        it "should set the grandchild's start date to the provided date" do
          grandchild.reload
          expect(grandchild.start_date).to eq(Date.today + 3.days)
        end

        it "should set the set grandchild's due date to the provided date plus the grandchild's duration" do
          grandchild.reload
          expect(grandchild.due_date).to eq(Date.today + 10.days)
        end
      end
    end
  end
end
