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

require 'spec_helper'

describe 'Wiki unicode title spec', type: :feature do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }
  let(:wiki_page_1) {
    FactoryGirl.build :wiki_page_with_content,
                       title: '<script>alert("FOO")</script>'
  }
  let(:wiki_page_2) {
    FactoryGirl.build :wiki_page_with_content,
                       title: 'Base de données'
  }
  let(:wiki_page_3) {
    FactoryGirl.build :wiki_page_with_content,
                       title: 'Base_de_données'
  }

  let(:wiki_body) {
    <<-EOS
    [[Base de données]]

    [[Base_de_données]]

    [[Base%20de%20données]]

    [[<script>alert("FOO")</script>]]

    [[&lt;script&gt;alert(&quot;FOO&quot;)&lt;/script&gt;]]
    EOS
  }

  let(:expected_titles) {
    [
      'Base de données',
      'Base_de_données',
      'Base de données',
      '<script>alert("FOO")</script>',
      '<script>alert("FOO")</script>'
    ]
  }

  before do
    login_as(user)

    project.wiki.pages << wiki_page_1
    project.wiki.pages << wiki_page_2
    project.wiki.pages << wiki_page_3

    project.wiki.save!

    visit project_wiki_path(project, :wiki)

    # Set value
    find('#content_text').set(wiki_body)
    click_button 'Save'

    expect(page).to have_selector('h1.wiki-title', text: 'wiki')
    expect(page).to have_selector('a.wiki-page', count: 5)
  end

  it 'shows renders correct links' do
    expected_titles.each_with_index do |title, i|
      visit project_wiki_path(project, :wiki)
      target_link = all('div.wiki-content a.wiki-page')[i]

      expect(target_link.text).to eq(title)
      target_link.click

      expect(page).to have_selector('h1.wiki-title', text: title)
    end
  end
end
