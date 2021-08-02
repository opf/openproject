#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'acts_as_watchable including model (e.g. WikiPage)', type: :model do
  let(:klass) { WikiPage }
  let(:project) { wiki.project }
  let(:wiki) { FactoryBot.create(:wiki) }
  let(:instance) { FactoryBot.create(:wiki_page, wiki: wiki) }

  describe '#watcher_recipients' do
    subject(:watcher_recipients) do
      instance.watcher_recipients
    end

    let(:watcher_all_notifications) do
      FactoryBot.create(:watcher,
                        watchable: instance,
                        user: watcher_user_all_notifications)
    end
    let(:watcher_user_all_notifications) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: %i(view_wiki_pages))
    end

    let(:watcher_watched_notifications) do
      FactoryBot.create(:watcher,
                        watchable: instance,
                        user: watcher_user_watched_notifications)
    end
    let(:watcher_user_watched_notifications) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: %i(view_wiki_pages)).tap do |user|
        user.notification_settings.mail.update_all(involved: false,
                                                   mentioned: false,
                                                   watched: true,
                                                   all: false)
      end
    end

    let(:watcher_no_notifications) do
      FactoryBot.create(:watcher,
                        watchable: instance,
                        user: watcher_user_no_notifications)
    end
    let(:watcher_user_no_notifications) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: %i(view_wiki_pages)).tap do |user|
        user.notification_settings.mail.update_all(involved: false,
                                                   mentioned: false,
                                                   watched: false,
                                                   all: false)
      end
    end

    let(:watcher_no_permission) do
      FactoryBot.create(:watcher,
                        :skip_validate,
                        watchable: instance,
                        user: watcher_user_no_permission)
    end
    let(:watcher_user_no_permission) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: %i())
    end

    let(:watcher_locked) do
      FactoryBot.create(:watcher,
                        :skip_validate,
                        watchable: instance,
                        user: watcher_user_no_permission)
    end
    let(:watcher_user_locked) do
      FactoryBot.create(:locked_user,
                        member_in_project: project,
                        member_with_permissions: %i(view_wiki_pages))
    end

    let(:non_watcher_user_all_notifications) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: %i(view_wiki_pages))
    end

    before do
      watcher_all_notifications
      watcher_watched_notifications
      watcher_no_notifications
      watcher_no_permission

      non_watcher_user_all_notifications
    end

    it 'includes users watching the instance and having notification settings and permissions' do
      expect(watcher_recipients)
        .to match_array([watcher_user_all_notifications, watcher_user_watched_notifications])
    end
  end
end
