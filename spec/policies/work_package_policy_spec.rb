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

require File.expand_path('../../spec_helper', __FILE__)

describe WorkPackagePolicy, type: :controller do
  let(:user)         { FactoryGirl.build_stubbed(:user) }
  let(:project)      { FactoryGirl.build_stubbed(:project) }
  let(:work_package) { FactoryGirl.build_stubbed(:work_package, project: project) }

  describe '#allowed?' do
    let(:subject) { described_class.new(user) }

    before do
      allow(user).to receive(:allowed_to?).and_return false
    end

    it 'is false for edit if the user has no permission in the project' do
      expect(subject.allowed?(work_package, :edit)).to be_falsey
    end

    it 'is true for edit if the user has the edit_work_package permission in the project' do
      allow(user).to receive(:allowed_to?).with(:edit_work_packages, project)
        .and_return true
      expect(subject.allowed?(work_package, :edit)).to be_truthy
    end

    it 'is true for edit if the user has the add_work_package_notes permission in the project' do
      allow(user).to receive(:allowed_to?).with(:add_work_package_notes, project)
        .and_return true
      expect(subject.allowed?(work_package, :edit)).to be_truthy
    end

    it 'is true if the user has the manage_subtasks permission in the project' do
      allow(user).to receive(:allowed_to?).with(:manage_subtasks, project)
        .and_return true
      expect(subject.allowed?(work_package, :manage_subtasks)).to be_truthy
    end
  end
end
