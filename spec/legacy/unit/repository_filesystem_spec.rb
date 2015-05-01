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
#++
require 'legacy_spec_helper'

describe Repository::Filesystem, type: :model do
  fixtures :all

  before do
    @project = Project.find(3)

    with_existing_filesystem_scm do |repo_path|
      assert @repository = Repository::Filesystem.create(project: @project,
                                                         url: repo_path)
    end
  end

  it 'should fetch changesets' do
    with_existing_filesystem_scm do
      @repository.fetch_changesets
      @repository.reload

      assert_equal 0, @repository.changesets.count
      assert_equal 0, @repository.changes.count
    end
  end

  it 'should entries' do
    with_existing_filesystem_scm do
      assert_equal 3, @repository.entries('', 2).size
      assert_equal 2, @repository.entries('dir', 3).size
    end
  end

  it 'should cat' do
    with_existing_filesystem_scm do
      assert_equal "TEST CAT\n", @repository.scm.cat('test')
    end
  end
end
