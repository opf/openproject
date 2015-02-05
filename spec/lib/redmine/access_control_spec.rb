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
describe Redmine::AccessControl do
  let(:global_permissions) { Redmine::AccessControl.permissions }
  let(:public_permissions) { Redmine::AccessControl.public_permissions }
  let(:members_only_permissions) { Redmine::AccessControl.members_only_permissions }
  let(:loggedin_only_permissions) { Redmine::AccessControl.loggedin_only_permissions }

  after(:all) do
    Redmine::AccessControl.map do |mapper|
      mapper.project_module :repository do |map|
        @repository_permissions.map do |permission|
          options = { project_module: permission.project_module,
                      public: permission.public?,
                      require: permission.require_loggedin? }

          map.permission(permission.name, permission.actions, options)
        end
      end
    end
  end

  before(:all) do
    module_permissions = Redmine::AccessControl.modules_permissions(['repository'])
    @repository_permissions = module_permissions.select do |permission|
      permission.project_module == :repository
    end
    Redmine::AccessControl.remove_modules_permissions(:repository)
  end

  describe 'remove module permissions' do
    context 'remove from global permissions' do
      it { expect(global_permissions).to_not include(@repository_permissions) }
    end

    context 'remove from public permissions' do
      it { expect(public_permissions).to_not include(@repository_permissions) }
    end

    context 'remove from members only permissions' do
      it { expect(members_only_permissions).to_not include(@repository_permissions) }
    end

    context 'remove from loggedin only permissions' do
      it { expect(loggedin_only_permissions).to_not include(@repository_permissions) }
    end
  end
end
