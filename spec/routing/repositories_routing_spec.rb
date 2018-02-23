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

describe RepositoriesController, type: :routing do
  describe 'show' do
    it {
      expect(get('/projects/testproject/repository'))
        .to route_to(controller: 'repositories',
                     action: 'show',
                     project_id: 'testproject')
    }

    it {
      expect(get('/projects/testproject/repository/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'show',
                     project_id: 'testproject',
                     path: 'path/to/file.c')
    }

    it {
      expect(get('/projects/testproject/repository/folder%20with%20spaces'))
        .to route_to(controller: 'repositories',
                     action: 'show',
                     project_id: 'testproject',
                     path: 'folder with spaces')
    }

    it {
      expect(get('/projects/testproject/repository/revisions/5'))
        .to route_to(controller: 'repositories',
                     action: 'show',
                     rev: '5',
                     project_id: 'testproject')
    }
  end

  describe 'show with git tags (regression test #27230)' do
    it {
      expect(get('/projects/testproject/repository/sub?rev=mytags%2Ffoo&branch=&tag=mytags%2Ffoo'))
        .to route_to(controller: 'repositories',
                     action: 'show',
                     path: 'sub',
                     branch: '',
                     rev: 'mytags/foo',
                     tag: 'mytags/foo',
                     project_id: 'testproject')
    }
    it {
      expect(get('/projects/testproject/repository?rev=FSubCommit-a&branch=master&tag=FSubCommit-a'))
        .to route_to(controller: 'repositories',
                     action: 'show',
                     branch: 'master',
                     rev: 'FSubCommit-a',
                     tag: 'FSubCommit-a',
                     project_id: 'testproject')
    }
    it {
      expect(get('/projects/testproject/repository/revisions/FSubCommit-a/sub'))
        .to route_to(controller: 'repositories',
                     action: 'show',
                     path: 'sub',
                     rev: 'FSubCommit-a',
                     project_id: 'testproject')
    }
  end

  describe 'edit' do
    it {
      expect(get('/projects/testproject/repository/edit'))
        .to route_to(controller: 'repositories',
                     action: 'edit',
                     project_id: 'testproject')
    }
  end

  describe 'create' do
    it {
      expect(post('/projects/testproject/repository/'))
        .to route_to(controller: 'repositories',
                     action: 'create',
                     project_id: 'testproject')
    }
  end

  describe 'update' do
    it {
      expect(put('/projects/testproject/repository/'))
        .to route_to(controller: 'repositories',
                     action: 'update',
                     project_id: 'testproject')
    }
  end

  describe 'revisions' do
    it {
      expect(get('/projects/testproject/repository/revisions'))
        .to route_to(controller: 'repositories',
                     action: 'revisions',
                     project_id: 'testproject')
    }

    it {
      expect(get('/projects/testproject/repository/revisions.atom'))
        .to route_to(controller: 'repositories',
                     action: 'revisions',
                     project_id: 'testproject',
                     format: 'atom')
    }
  end

  describe 'revision' do
    it {
      expect(get('/projects/testproject/repository/revision/2457'))
        .to route_to(controller: 'repositories',
                     action: 'revision',
                     project_id: 'testproject',
                     rev: '2457')
    }

    it {
      expect(get('/projects/testproject/repository/revision'))
        .to route_to(controller: 'repositories',
                     action: 'revision',
                     project_id: 'testproject')
    }
  end

  describe 'diff' do
    it {
      expect(get('/projects/testproject/repository/revisions/2457/diff'))
        .to route_to(controller: 'repositories',
                     action: 'diff',
                     project_id: 'testproject',
                     rev: '2457')
    }

    it {
      expect(get('/projects/testproject/repository/revisions/2457/diff.diff'))
        .to route_to(controller: 'repositories',
                     action: 'diff',
                     project_id: 'testproject',
                     rev: '2457',
                     format: 'diff')
    }

    it {
      expect(get('/projects/testproject/repository/diff'))
        .to route_to(controller: 'repositories',
                     action: 'diff',
                     project_id: 'testproject')
    }

    it {
      expect(get('/projects/testproject/repository/diff/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'diff',
                     project_id: 'testproject',
                     path: 'path/to/file.c')
    }

    it {
      expect(get('/projects/testproject/repository/revisions/2/diff/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'diff',
                     project_id: 'testproject',
                     path: 'path/to/file.c',
                     rev: '2')
    }
  end

  describe 'browse' do
    it {
      expect(get('/projects/testproject/repository/browse/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'browse',
                     project_id: 'testproject',
                     path: 'path/to/file.c')
    }
  end

  describe 'entry' do
    it {
      expect(get('/projects/testproject/repository/entry/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'entry',
                     project_id: 'testproject',
                     path: 'path/to/file.c')
    }

    it {
      expect(get('/projects/testproject/repository/revisions/2/entry/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'entry',
                     project_id: 'testproject',
                     path: 'path/to/file.c',
                     rev: '2')
    }

    it {
      expect(get('/projects/testproject/repository/raw/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'entry',
                     project_id: 'testproject',
                     path: 'path/to/file.c',
                     format: 'raw')
    }

    it {
      expect(get('/projects/testproject/repository/revisions/master/raw/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'entry',
                     project_id: 'testproject',
                     path: 'path/to/file.c',
                     rev: 'master',
                     format: 'raw')
    }
  end

  describe 'annotate' do
    it {
      expect(get('/projects/testproject/repository/annotate/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'annotate',
                     project_id: 'testproject',
                     path: 'path/to/file.c')
    }
    it {
      expect(get('/projects/testproject/repository/revisions/5/annotate/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'annotate',
                     project_id: 'testproject',
                     path: 'path/to/file.c',
                     rev: '5')
    }
  end

  describe 'changes' do
    it {
      expect(get('/projects/testproject/repository/changes/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'changes',
                     project_id: 'testproject',
                     path: 'path/to/file.c')
    }

    it {
      expect(get('/projects/testproject/repository/revisions/5/changes/path/to/file.c'))
        .to route_to(controller: 'repositories',
                     action: 'changes',
                     project_id: 'testproject',
                     path: 'path/to/file.c',
                     rev: '5')
    }
  end

  describe 'stats' do
    it {
      expect(get('/projects/testproject/repository/statistics'))
        .to route_to(controller: 'repositories',
                     action: 'stats',
                     project_id: 'testproject')
    }
  end

  describe 'committers' do
    it {
      expect(get('/projects/testproject/repository/committers'))
        .to route_to(controller: 'repositories',
                     action: 'committers',
                     project_id: 'testproject')
    }

    it {
      expect(post('/projects/testproject/repository/committers'))
        .to route_to(controller: 'repositories',
                     action: 'committers',
                     project_id: 'testproject')
    }
  end

  describe 'graph' do
    it {
      expect(get('/projects/testproject/repository/graph'))
        .to route_to(controller: 'repositories',
                     action: 'graph',
                     project_id: 'testproject')
    }
  end

  describe 'destroy' do
    it {
      expect(delete('/projects/testproject/repository'))
        .to route_to(controller: 'repositories',
                     action: 'destroy',
                     project_id: 'testproject')
    }
  end

  describe 'destroy_info' do
    it {
      expect(get('/projects/testproject/repository/destroy_info'))
        .to route_to(controller: 'repositories',
                     action: 'destroy_info',
                     project_id: 'testproject')
    }
  end
end
