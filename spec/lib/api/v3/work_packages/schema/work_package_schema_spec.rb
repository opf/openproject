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
  context 'created from work package' do
    let(:work_package) { FactoryGirl.build(:work_package) }
    subject { described_class.new(work_package: work_package) }

    it 'defines assignable values' do
      expect(subject.defines_assignable_values?).to be_true
    end

    describe '#assignable_statuses_for' do
      let(:user) { double }
      let(:status_result) { double }

      before do
        allow(work_package).to receive(:is_persisted?).and_return(false)
        allow(work_package).to receive(:status_id_changed?).and_return(false)
      end

      it 'calls through to the work package' do
        expect(work_package).to receive(:new_statuses_allowed_to).with(user)
          .and_return(status_result)
        expect(subject.assignable_statuses_for(user)).to eql(status_result)
      end

      context 'changed work package' do
        let(:work_package) { FactoryGirl.create(:work_package) }
        let(:stored_wp) { FactoryGirl.build(:work_package, id: work_package.id) }

        before do
          allow(work_package).to receive(:status_id_changed?).and_return(true)
          allow(WorkPackage).to receive(:find).with(work_package.id).and_return(stored_wp)
        end

        it 'calls through to the stored work package' do
          expect(work_package).to_not receive(:new_statuses_allowed_to)
          expect(stored_wp).to receive(:new_statuses_allowed_to).with(user)
            .and_return(status_result)
          expect(subject.assignable_statuses_for(user)).to eql(status_result)
        end
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
      let(:result) { double }

      it 'calls through to the work package' do
        expect(work_package).to receive(:assignable_priorities).and_return(result)
        expect(subject.assignable_priorities).to eql(result)
      end
    end
  end

  context 'created from project and type' do
    let(:project) { FactoryGirl.build(:project) }
    let(:type) { FactoryGirl.build(:type) }
    subject { described_class.new(project: project, type: type) }

    it 'does not define assignable values' do
      expect(subject.defines_assignable_values?).to be_false
    end
  end
end
