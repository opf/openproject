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

describe ::API::V3::WorkPackages::Schema::TypedWorkPackageSchema do
  let(:project) { FactoryGirl.build(:project) }
  let(:type) { FactoryGirl.build(:type) }

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

  describe '#writable?' do
    it 'percentage done is writable' do
      expect(subject.writable?(:percentage_done)).to be true
    end

    it 'estimated time is writable' do
      expect(subject.writable?(:estimated_time)).to be true
    end

    it 'start date is writable' do
      expect(subject.writable?(:start_date)).to be true
    end

    it 'due date is writable' do
      expect(subject.writable?(:due_date)).to be true
    end
  end
end
