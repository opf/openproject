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

describe OpenProject::Reporting::DefaultData do
  let(:seeder) { BasicData::RoleSeeder.new }
  let(:project_admin) { OpenProject::Reporting::DefaultData.project_admin_role }
  let(:permissions) do
    OpenProject::Reporting::DefaultData.restricted_project_admin_permissions
  end

  before do
    allow(seeder).to receive(:builtin_roles).and_return([])

    seeder.seed!
  end

  it 'removes permissions from the project admin role' do
    expect(project_admin.permissions).not_to include *permissions
  end

  it 'is not loaded again on existing data' do
    project_admin.add_permission! *permissions
    project_admin.save!

    # on existing data the permissions should not be removed
    seeder.seed!

    project_admin.reload
    expect(project_admin.permissions).to include *permissions
  end
end
