#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "project settings index" do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[manage_versions] })
  end
  let(:project) { create(:project) }
  let!(:version1) { create(:version, name: "aaaaa 1.", project:) }
  let!(:version2) { create(:version, name: "aaaaa", project:) }
  let!(:version3) { create(:version, name: "1.10. aaa", project:) }
  let!(:version4) { create(:version, name: "1.1. zzz", project:) }
  let!(:version5) { create(:version, name: "1.2. mmm", project:) }
  let!(:version6) { create(:version, name: "1. xxxx", project:) }

  before do
    login_as(user)
  end

  @javascript
  it "see versions listed in semver order" do
    visit project_settings_versions_path(project)

    names_in_order = page.all(".version .name").map { |el| el.text.strip }

    expect(names_in_order)
      .to eql [version6.name, version4.name, version5.name, version3.name, version2.name, version1.name]
  end
end
