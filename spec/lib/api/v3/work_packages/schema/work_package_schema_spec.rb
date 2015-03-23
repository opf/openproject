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

describe ::API::V3::WorkPackages::Schema::WorkPackageSchema do
  let(:project) { FactoryGirl.build(:project) }
  let(:type) { FactoryGirl.build(:type) }
  let(:work_package) {
    FactoryGirl.build(:work_package,
                      project: project,
                      type: type)
  }

  context 'created from work package' do
    subject { described_class.new(work_package: work_package) }

    it 'has the project set' do
      expect(subject.project).to eql(project)
    end

    it 'has the type set' do
      expect(subject.type).to eql(type)
    end

    describe '#assignable_statuses_for' do
      let(:user) { double('current user') }
      let(:status_result) { double('status result') }

      before do
        allow(work_package).to receive(:persisted?).and_return(false)
        allow(work_package).to receive(:status_id_changed?).and_return(false)
      end

      it 'calls through to the work package' do
        expect(work_package).to receive(:new_statuses_allowed_to).with(user)
          .and_return(status_result)
        expect(subject.assignable_statuses_for(user)).to eql(status_result)
      end

      context 'changed work package' do
        let(:work_package) {
          double('original work package',
                 id: double,
                 clone: cloned_wp,
                 status: double('wrong status'),
                 persisted?: true).as_null_object
        }
        let(:cloned_wp) {
          double('cloned work package',
                 new_statuses_allowed_to: status_result)
        }
        let(:stored_status) {
          double('good status')
        }

        before do
          allow(work_package).to receive(:persisted?).and_return(true)
          allow(work_package).to receive(:status_id_changed?).and_return(true)
          allow(Status).to receive(:find_by_id)
            .with(work_package.status_id_was).and_return(stored_status)
        end

        it 'calls through to the cloned work package' do
          expect(cloned_wp).to receive(:status=).with(stored_status)
          expect(cloned_wp).to receive(:new_statuses_allowed_to).with(user)
          expect(subject.assignable_statuses_for(user)).to eql(status_result)
        end
      end
    end

    describe '#available_custom_fields' do
      let(:cf1) { double }
      let(:cf2) { double }
      let(:cf3) { double }

      before do
        scope_double = double
        allow(scope_double).to receive(:all).and_return([cf1, cf2])
        allow(type).to receive(:custom_fields).and_return(scope_double)
        allow(project).to receive(:all_work_package_custom_fields).and_return([cf2, cf3])
      end

      it 'is expected to return custom fields available in project AND type' do
        expect(subject.available_custom_fields).to eql([cf2])
      end

      context 'type missing' do
        let(:type) { nil }
        it 'returns an empty list' do
          expect(subject.available_custom_fields).to eql([])
        end
      end

      context 'project missing' do
        let(:project) { nil }
        it 'returns an empty list' do
          expect(subject.available_custom_fields).to eql([])
        end
      end
    end

    describe '#assignable_types' do
      let(:result) { double }

      it 'calls through to the project' do
        expect(project).to receive(:types).and_return(result)
        expect(subject.assignable_types).to eql(result)
      end
    end

    describe '#assignable_versions' do
      let(:result) { double }

      it 'calls through to the work package' do
        expect(work_package).to receive(:assignable_versions).and_return(result)
        expect(subject.assignable_versions).to eql(result)
      end
    end

    describe '#assignable_priorities' do
      let(:active_priority) { FactoryGirl.build(:priority, active: true) }
      let(:inactive_priority) { FactoryGirl.build(:priority, active: false) }

      before do
        active_priority.save!
        inactive_priority.save!
      end

      it 'returns only active priorities' do
        expect(subject.assignable_priorities.size).to be >= 1
        subject.assignable_priorities.each do |priority|
          expect(priority.active).to be_truthy
        end
      end
    end

    describe '#assignable_categories' do
      let(:category) { double('category') }

      before do
        allow(project).to receive(:categories).and_return([category])
      end

      it 'returns all categories of the project' do
        expect(subject.assignable_categories).to match_array([category])
      end
    end

    describe 'utility methods' do
      context 'leaf' do
        let(:work_package) { FactoryGirl.create(:work_package) }

        it 'detects leaf' do
          expect(subject.nil_or_leaf? work_package).to be true
        end
      end

      context 'parent' do
        let(:child) { FactoryGirl.build(:work_package, project: project, type: type) }
        let(:parent) do
          FactoryGirl.build(:work_package, project: project, type: type, children: [child])
        end

        it 'detects parent' do
          expect(subject.nil_or_leaf? parent).to be false
        end
      end

      context 'percentage done' do
        it 'is not writable when inferred by status' do
          allow(Setting).to receive(:work_package_done_ratio).and_return('status')

          expect(subject.percentage_done_writable?).to be false
        end

        it 'is not writable when disabled' do
          allow(Setting).to receive(:work_package_done_ratio).and_return('disabled')

          expect(subject.percentage_done_writable?).to be false
        end
      end
    end
  end

  context 'created from project and type' do
    let(:user) { double }
    subject { described_class.new(project: project, type: type) }

    it 'has the project set' do
      expect(subject.project).to eql(project)
    end

    it 'has the type set' do
      expect(subject.type).to eql(type)
    end

    it 'does not know assignable statuses' do
      expect(subject.assignable_statuses_for(user)).to eql(nil)
    end

    it 'does not know assignable versions' do
      expect(subject.assignable_versions).to eql(nil)
    end

    describe 'leaf or nil' do
      it 'evaluates nil work package as nil' do
        expect(subject.nil_or_leaf? nil).to be true
      end
    end
  end
end
