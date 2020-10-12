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

describe 'Disabled activity', type: :feature do
  using_shared_fixtures :admin

  let(:project1) do
    FactoryBot.create(:project, enabled_module_names: %i[work_package_tracking wiki])
  end
  let(:project2) do
    FactoryBot.create(:project, enabled_module_names: %i[work_package_tracking activity wiki])
  end
  let(:project3) do
    FactoryBot.create(:project, enabled_module_names: %i[activity])
  end
  let!(:work_package1) { FactoryBot.create(:work_package, project: project1) }
  let!(:work_package2) { FactoryBot.create(:work_package, project: project2) }
  let!(:work_package3) { FactoryBot.create(:work_package, project: project3) }
  let!(:wiki_page1) do
    FactoryBot.create(:wiki_page, wiki: project1.wiki) do |page|
      FactoryBot.create(:wiki_content, page: page)
    end
  end
  let!(:wiki_page2) do
    FactoryBot.create(:wiki_page, wiki: project2.wiki) do |page|
      FactoryBot.create(:wiki_content, page: page)
    end
  end
  let!(:wiki_page3) do
    wiki = FactoryBot.create(:wiki, project: project3)

    FactoryBot.create(:wiki_page, wiki: wiki) do |page|
      FactoryBot.create(:wiki_content, page: page)
    end
  end

  before do
    login_as(admin)
  end

  it 'does not display activities on projects disabling it' do
    visit activity_index_path

    check "Wiki edits"
    click_on "Apply"

    expect(page)
      .to have_content(work_package2.subject)
    expect(page)
      .to have_content(wiki_page2.title)

    # Not displayed as activity is disabled
    expect(page)
      .not_to have_content(work_package1.subject)
    expect(page)
      .not_to have_content(wiki_page1.title)

    # Not displayed as all modules except activity are disabled
    expect(page)
      .not_to have_content(work_package3.subject)
    expect(page)
      .not_to have_content(wiki_page3.title)
  end
end
