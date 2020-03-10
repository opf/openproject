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

require 'spec_helper'

describe OpenProject::AccessControl do
  describe '.remove_modules_permissions' do
    let!(:all_former_permissions) { OpenProject::AccessControl.permissions }
    let!(:former_repository_permissions) do
      module_permissions = OpenProject::AccessControl.modules_permissions(['repository'])

      module_permissions.select do |permission|
        permission.project_module == :repository
      end
    end

    subject { OpenProject::AccessControl }

    before do
      OpenProject::AccessControl.remove_modules_permissions(:repository)
    end

    after do
      raise 'Test outdated' unless OpenProject::AccessControl.instance_variable_defined?(:@permissions)
      OpenProject::AccessControl.instance_variable_set(:@permissions, all_former_permissions)
      OpenProject::AccessControl.clear_caches
    end

    it 'removes from global permissions' do
      expect(subject.permissions).not_to include(former_repository_permissions)
    end

    it 'removes from public permissions' do
      expect(subject.public_permissions).not_to include(former_repository_permissions)
    end

    it 'removes from members only permissions' do
      expect(subject.members_only_permissions).not_to include(former_repository_permissions)
    end

    it 'removes from loggedin only permissions' do
      expect(subject.loggedin_only_permissions).not_to include(former_repository_permissions)
    end

    it 'should disable repository module' do
      expect(subject.available_project_modules).not_to include(:repository)
    end
  end

  describe '#permissions' do
    it 'is an array of permissions' do
      expect(described_class.permissions.all? { |p| p.is_a?(OpenProject::AccessControl::Permission) })
        .to be_truthy
    end
  end

  describe '#permission' do
    context 'for a project module permission' do
      subject { described_class.permission(:view_work_packages) }

      it 'is a permission' do
        is_expected
          .to be_a(OpenProject::AccessControl::Permission)
      end

      it 'is the permission with the queried for name' do
        expect(subject.name)
          .to eql(:view_work_packages)
      end

      it 'belongs to a project module' do
        expect(subject.project_module)
          .to eql(:work_package_tracking)
      end
    end

    context 'for a non module permission' do
      subject { described_class.permission(:edit_project) }

      it 'is a permission' do
        is_expected
          .to be_a(OpenProject::AccessControl::Permission)
      end

      it 'is the permission with the queried for name' do
        expect(subject.name)
          .to eql(:edit_project)
      end

      it 'belongs to a project module' do
        expect(subject.project_module)
          .to be_nil
      end

      it 'includes actions' do
        expect(subject.actions)
          .to include('project_settings/show')
      end
    end
  end

  describe '#dependencies' do
    context 'for a permission with a prerequisite' do
      subject { described_class.permission(:edit_work_packages) }

      it 'denotes the prerequiresites' do
        expect(subject.dependencies)
          .to match_array([:view_work_packages])
      end
    end

    context 'for a permission without a prerequisite' do
      subject { described_class.permission(:view_work_packages) }

      it 'denotes the prerequiresites' do
        expect(subject.dependencies)
          .to be_empty
      end
    end
  end
end
