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

describe WikiContent, type: :model do
  let(:wiki) { FactoryBot.create(:wiki) }
  let(:page) { FactoryBot.create(:wiki_page, wiki: wiki) }
  let(:content) { FactoryBot.create(:wiki_content, page: page, author: author) }
  let(:author) { FactoryBot.create(:user, member_in_project: wiki.project, member_with_permissions: [:view_wiki_pages]) }
  let(:page_watcher) do
    watcher = FactoryBot.create(:user,
                                member_in_project: wiki.project,
                                member_with_permissions: [:view_wiki_pages])
    page.watcher_users << watcher

    watcher
  end

  let(:wiki_watcher) do
    watcher = FactoryBot.create(:user,
                                member_in_project: wiki.project,
                                member_with_permissions: [:view_wiki_pages])
    wiki.watcher_users << watcher

    watcher
  end

  describe '#save (create)' do
    let(:content) { FactoryBot.build(:wiki_content, page: page) }

    it 'sends mails to the wiki`s watchers', with_settings: { notified_events: ['wiki_content_added'] } do
      wiki_watcher

      expect {
        content.save!
        perform_enqueued_jobs
      }
        .to change { ActionMailer::Base.deliveries.size }
        .by(1)
    end
  end

  describe '#save (update)' do
    it 'sends mails to the author, the watchers and the wiki`s watchers', with_settings: { notified_events: ['wiki_content_updated'] } do
      page_watcher
      wiki_watcher
      content.text = 'My new content'

      expect {
        content.save!
        perform_enqueued_jobs
      }
        .to change { ActionMailer::Base.deliveries.size }
        .by(3)
    end
  end
end
