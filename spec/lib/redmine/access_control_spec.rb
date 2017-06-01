#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
describe Redmine::AccessControl do
  describe '.remove_modules_permissions' do
    let!(:all_former_permissions) { Redmine::AccessControl.permissions }
    let!(:former_repository_permissions) do
      module_permissions = Redmine::AccessControl.modules_permissions(['repository'])

      module_permissions.select do |permission|
        permission.project_module == :repository
      end
    end

    subject { Redmine::AccessControl }

    before do
      Redmine::AccessControl.remove_modules_permissions(:repository)
    end

    after do
      raise 'Test outdated' unless Redmine::AccessControl.instance_variable_defined?(:@permissions)
      Redmine::AccessControl.instance_variable_set(:@permissions, all_former_permissions)
      Redmine::AccessControl.clear_caches
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
end
