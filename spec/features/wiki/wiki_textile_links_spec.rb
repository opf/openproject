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

describe 'Wiki unicode title spec', type: :feature, js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }
  let(:wiki_page_1) {
    FactoryGirl.build :wiki_page_with_content, title: 'Test'
  }
  let(:work_package) {
    FactoryGirl.create :work_package,
                       project: project,
                       start_date: Date.today,
                       due_date: Date.today + 1.days,
                       assigned_to: user
  }
  let(:wp_id) { work_package.id }

  let(:wiki_body) {
    <<-EOS

    **1 quickinfo**
    ##{wp_id}

    **2 quickinfo**
    ###{wp_id}

    **3 quickinfo**
    ####{wp_id}

    EOS
  }

  before do
    login_as(user)

    project.wiki.pages << wiki_page_1
    project.wiki.save!

    visit project_wiki_path(project, :wiki)

    # Set value
    find('#content_text').set(wiki_body)
    click_button 'Save'

    expect(page).to have_selector('.title-container h2', text: 'wiki')
  end

  it 'renders correct links' do

    expect(page).to have_selector('a.issue', count: 3)

    links = page.all('a.issue')

    expect(links[0].text).to eq("##{wp_id}")
    expect(links[0][:href]).to include(work_package_path(wp_id))
    expect(links[1].text).to eq("#{work_package.type.name} ##{wp_id} #{work_package.status.name}")
    expect(links[1][:href]).to include(work_package_path(wp_id))
    expect(links[2].text).to eq("#{work_package.type.name} ##{wp_id} #{work_package.status.name}")
    expect(links[2][:href]).to include(work_package_path(wp_id))
  end
end
