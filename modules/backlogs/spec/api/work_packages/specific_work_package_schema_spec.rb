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

describe ::API::V3::WorkPackages::Schema::SpecificWorkPackageSchema do
  let(:project) { FactoryBot.build(:project) }
  let(:type) { FactoryBot.build(:type) }
  let(:work_package) do
    FactoryBot.build(:work_package,
                      project: project,
                      type: type)
  end

  describe '#remaining_time_writable?' do
    subject { described_class.new(work_package: work_package) }

    context 'work_package is a leaf' do
      before do
        allow(work_package).to receive(:leaf?).and_return(true)
      end

      it 'is writable' do
        expect(subject.writable?(:remaining_time)).to eql(true)
      end
    end

    context 'work_package is no leaf' do
      before do
        allow(work_package).to receive(:leaf?).and_return(false)
      end

      it 'is not writable' do
        expect(subject.writable?(:remaining_time)).to eql(false)
      end
    end
  end

  describe '#version_writable?' do
    subject { described_class.new(work_package: work_package) }

    context 'work_package is a task' do
      before do
        allow(work_package)
          .to receive(:is_task?)
          .and_return(true)
      end

      it 'is writable' do
        expect(subject.writable?(:version)).to eql(false)
      end
    end

    context 'work_package is no task' do
      before do
        allow(work_package)
          .to receive(:is_task?)
          .and_return(false)
      end

      it 'is not writable' do
        expect(subject.writable?(:version)).to eql(true)
      end
    end
  end
end
