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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenProject::AccessControl do
  before(:each) do
    stash_access_control_permissions

    OpenProject::AccessControl.map do |map|
      map.permission :proj0, { dont: :care }, require: :member
      map.permission :global0, { dont: :care }, global: true
      map.permission :proj1, { dont: :care }

      map.project_module :global_module do |mod|
        mod.permission :global1, { dont: :care }, global: true
      end

      map.project_module :project_module do |mod|
        mod.permission :proj2, { dont: :care }
      end

      map.project_module :mixed_module do |mod|
        mod.permission :proj3, { dont: :care }
        mod.permission :global2, { dont: :care }, global: true
      end
    end
  end

  after(:each) do
    restore_access_control_permissions
  end

  describe 'class methods' do
    describe '#global_permissions' do
      it { expect(OpenProject::AccessControl.global_permissions.size).to eq(3) }
      it { expect(OpenProject::AccessControl.global_permissions.collect(&:name)).to include(:global0) }
      it { expect(OpenProject::AccessControl.global_permissions.collect(&:name)).to include(:global1) }
      it { expect(OpenProject::AccessControl.global_permissions.collect(&:name)).to include(:global2) }
    end

    describe '#available_project_modules' do
      it { expect(OpenProject::AccessControl.available_project_modules.include?(:global_module)).to be_falsey }
      it { expect(OpenProject::AccessControl.available_project_modules.include?(:global_module)).to be_falsey }
      it { expect(OpenProject::AccessControl.available_project_modules.include?(:mixed_module)).to be_truthy }
    end
  end
end
