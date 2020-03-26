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

feature 'project settings index', type: :feature do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[manage_versions])
  end
  let(:project) { FactoryBot.create(:project) }
  let!(:version1) { FactoryBot.create(:version, name: "aaaaa 1.", project: project) }
  let!(:version2) { FactoryBot.create(:version, name: "aaaaa", project: project) }
  let!(:version3) { FactoryBot.create(:version, name: "1.10. aaa", project: project) }
  let!(:version4) { FactoryBot.create(:version, name: "1.1. zzz", project: project) }
  let!(:version5) { FactoryBot.create(:version, name: "1.2. mmm", project: project) }
  let!(:version6) { FactoryBot.create(:version, name: "1. xxxx", project: project) }

  before do
    login_as(user)
  end

  scenario 'see versions listed in semver order' do
    visit settings_versions_project_path(project)

    names_in_order = page.all('.version .name').map { |el| el.text.strip }

    expect(names_in_order)
      .to eql [version6.name, version4.name, version5.name, version3.name, version2.name, version1.name]
  end
end
