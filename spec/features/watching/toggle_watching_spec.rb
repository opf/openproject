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

describe 'Toggle watching', type: :feature, js: true do
  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_messages, :view_wiki_pages]) }
  let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
  let(:news) { FactoryBot.create(:news, project: project) }
  let(:forum) { FactoryBot.create(:forum, project: project) }
  let(:message) { FactoryBot.create(:message, forum: forum) }
  let(:wiki) { project.wiki }
  let(:wiki_page) { FactoryBot.create(:wiki_page_with_content, wiki: wiki) }

  before do
    allow(User).to receive(:current).and_return user
  end

  it 'can toggle watch and unwatch' do
    # Work packages have a different toggle and are hence not considered here
    [news_path(news),
     project_forum_path(project, forum),
     topic_path(message),
     project_wiki_path(project, wiki_page)].each do |path|
       visit path

       click_link(I18n.t('button_watch'))

       expect(page).to have_link(I18n.t('button_unwatch'))

       click_link(I18n.t('button_unwatch'))

       expect(page).to have_link(I18n.t('button_watch'))
     end
  end
end
