#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'spec_helper'

describe Redmine::AccessControl do
  let(:view_project_permission) { Redmine::AccessControl.permission(:view_project) }
  let(:edit_project_permission) { Redmine::AccessControl.permission(:edit_project) }

  describe '#view_project' do
    it { expect(view_project_permission.actions).to be_include("my_projects_overviews/index") }
  end

  describe '#edit_project' do
    it { expect(edit_project_permission.actions).to be_include("my_projects_overviews/page_layout") }
    it { expect(edit_project_permission.actions).to be_include("my_projects_overviews/add_block") }
    it { expect(edit_project_permission.actions).to be_include("my_projects_overviews/save_changes") }
    it { expect(edit_project_permission.actions).to be_include("my_projects_overviews/render_attachments") }
    it { expect(edit_project_permission.actions).to be_include("my_projects_overviews/update_custom_element") }
    it { expect(edit_project_permission.actions).to be_include("my_projects_overviews/destroy_attachment") }
  end
end
