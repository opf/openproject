#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
describe OpenProject::Plugins::ModuleHandler do
  before { @permissions = Redmine::AccessControl.modules_permissions(['repository']) }

  after do
    Redmine::AccessControl.map do |mapper|
      mapper.project_module :repository do |map|
        @permissions.map do |permission|
          options = { project_module: permission.project_module,
                      public: permission.public?,
                      require: permission.require_loggedin? }

          map.permission(permission.name, permission.actions, options)
        end
      end
    end
  end

  describe '#disable' do
    disabled_modules = OpenProject::Plugins::ModuleHandler.disable_modules('repository')
    OpenProject::Plugins::ModuleHandler.disable(disabled_modules)

    it { expect(Redmine::AccessControl.available_project_modules).to_not include(:repository) }
  end
end
