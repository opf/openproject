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
describe Redmine::AccessControl do
  after do
    Redmine::AccessControl.map do |mapper|
      mapper.project_module :repository do |map|
        map.permission :manage_repository,
                       { repositories: [:edit, :committers, :destroy] },
                       require: :member

        map.permission :browse_repository,
                       repositories: [:show, :browse, :entry,
                                      :annotate, :changes, :diff,
                                      :stats, :graph]

        map.permission :view_changesets, repositories: [:show, :revisions, :revision]
        map.permission :commit_access, {}
        map.permission :view_commit_author_statistics, {}
      end
    end
  end
  
  describe '#remove_modules_permissions' do
    before_delete = Redmine::AccessControl.permissions.map(&:name)
    Redmine::AccessControl.remove_modules_permissions(:repository)
    after_delete = Redmine::AccessControl.permissions.map(&:name)

    it { expect(after_delete).to_not eql(before_delete) }
  end
end
