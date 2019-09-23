#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe WorkPackage, '#reschedule_after', type: :model do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.build(:project_with_types) }
  let(:work_package) { FactoryBot.create(:work_package, project: project, type: project.types.first) }
  let(:work_package2) { FactoryBot.create(:work_package, project: project, type: project.types.first) }
  let(:work_package3) { FactoryBot.create(:work_package, project: project, type: project.types.first) }

  let(:instance) { work_package }
  let(:child) do
    work_package2.parent = instance

    work_package2
  end
  let(:grandchild) do
    work_package3.parent = child

    work_package3
  end

  before do
    login_as(user)
  end

  describe 'for a single node having start and finish date' do
    before do
      instance.start_date = Date.today
      instance.due_date = Date.today + 7.days

      instance.reschedule_after(Date.today + 3.days)
    end

    it 'should set the start_date to the provided date' do
      expect(instance.start_date).to eq(Date.today + 3.days)
    end

    it 'should set the set the finish date plus the duration' do
      expect(instance.due_date).to eq(Date.today + 10.days)
    end
  end

  describe 'for a single node having neither start nor finish date' do
    before do
      instance.start_date = nil
      instance.due_date = nil

      instance.reschedule_after(Date.today + 3.days)
    end

    it 'should set the start_date to the provided date' do
      expect(instance.start_date).to eq(Date.today + 3.days)
    end

    it 'should set the set the finish date plus the duration' do
      expect(instance.due_date).to eq(Date.today + 3.days)
    end
  end

  describe 'for a single node having only a finish date' do
    before do
      instance.start_date = nil
      instance.due_date = Date.today + 7.days

      instance.reschedule_after(Date.today + 3.days)
    end

    it 'should set the start_date to the provided date' do
      expect(instance.start_date).to eq(Date.today + 3.days)
    end

    it 'should set the set the finish date plus the duration' do
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

    it "should set the set the finish date to the provided date plus the child's duration" do
      instance.reload
      expect(instance.due_date).to eq(Date.today + 10.days)
    end

    it "should set the child's start date to the provided date" do
      child.reload
      expect(child.start_date).to eq(Date.today + 3.days)
    end

    it "should set the set child's finish date to the provided date plus the child's duration" do
      child.reload
      expect(child.due_date).to eq(Date.today + 10.days)
    end
  end

  describe "with a child
            while the new date is set to be between the child's start and finish date" do
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

    it "should set the set the finish date to the provided date plus the child's duration" do
      instance.reload
      expect(instance.due_date).to eq(Date.today + 9.days)
    end

    it "should set the child's start date to the provided date" do
      child.reload
      expect(child.start_date).to eq(Date.today + 3.days)
    end

    it "should set the set child's finish date to the provided date plus the child's duration" do
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

    it "should set the set the finish date to the provided date plus the child's duration" do
      instance.reload
      expect(instance.due_date).to eq(Date.today + 10.days)
    end

    it "should set the child's start date to the provided date" do
      child.reload
      expect(child.start_date).to eq(Date.today + 3.days)
    end

    it "should set the set child's finish date to the provided date plus the grandchild's duration" do
      child.reload
      expect(child.due_date).to eq(Date.today + 10.days)
    end

    it "should set the grandchild's start date to the provided date" do
      grandchild.reload
      expect(grandchild.start_date).to eq(Date.today + 3.days)
    end

    it "should set the set grandchild's finish date to the provided date plus the grandchild's duration" do
      grandchild.reload
      expect(grandchild.due_date).to eq(Date.today + 10.days)
    end
  end
end
