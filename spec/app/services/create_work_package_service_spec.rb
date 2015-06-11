#-- encoding: UTF-8
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

require 'spec_helper'

describe CreateWorkPackageService do
  let(:user) { FactoryGirl.build(:user) }
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:project) { FactoryGirl.build(:project_with_types) }

  before do
    allow(project).to receive(:add_work_package).and_return(work_package)
  end

  subject(:service) { CreateWorkPackageService.new(user: user, project: project) }

  describe 'should use meaningful defaults for creation' do
    it 'should use the project' do
      expect(project).to receive(:add_work_package).with(hash_including(project: project))
    end

    it 'should use the user' do
      expect(project).to receive(:add_work_package).with(hash_including(author: user))
    end

    it 'should use a type' do
      expect(project).to receive(:add_work_package).with(hash_including(:type))
    end

    it 'should have a non-empty type' do
      expect(project).to receive(:add_work_package).with(hash_excluding(type: nil))
    end

    after do
      service.create
    end
  end

  it 'should create an unsaved work_package' do
    expect(service.create.new_record?).to be_truthy
  end

  it 'should #save records' do
    wp = service.create
    service.save(wp)
    expect(WorkPackage.exists?(wp.id)).to be_truthy
  end
end
