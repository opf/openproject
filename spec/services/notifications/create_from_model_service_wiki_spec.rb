#-- encoding: UTF-8

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
require_relative './create_from_journal_job_shared'

describe Notifications::CreateFromModelService, 'wiki', with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:call) do
    described_class.new(journal).call(send_notifications)
  end

  include_context 'with CreateFromJournalJob context'

  shared_let(:project) { FactoryBot.create(:project) }
  shared_let(:wiki) { FactoryBot.create(:wiki, project: project) }

  let(:permissions) { [:view_wiki_pages] }
  let(:send_notifications) { true }

  let(:wiki_page) do
    FactoryBot.create(:wiki_page,
                      wiki: wiki,
                      content: FactoryBot.build(:wiki_content,
                                                author: other_user))
  end
  let(:resource) { wiki_page.content }
  let(:journal) { resource.journals.last }
  let(:author) { other_user }

  current_user { other_user }

  before do
    recipient
  end

  describe '#perform' do
    context 'with a newly created wiki page' do
      context 'with the user having registered for all notifications' do
        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason_ian: false,
              read_mail: false,
              reason_mail: :subscribed,
              read_mail_digest: nil,
              reason_mail_digest: false
            }
          end
        end
      end

      context 'with the user having registered for involved notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: true)),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true)),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for no notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and watching the wiki' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        before do
          wiki.watcher_users << recipient
        end

        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason_ian: false,
              read_mail: false,
              reason_mail: :watched,
              read_mail_digest: nil,
              reason_mail_digest: false
            }
          end
        end
      end

      context 'with the user not having registered for watcher notifications and watching the wiki' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
          ]
        end

        before do
          wiki.watcher_users << recipient
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and not watching the wiki' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for all notifications but lacking permissions' do
        let(:permissions) { [] }

        it_behaves_like 'creates no notification'
      end
    end

    context 'with an updated wiki page' do
      before do
        resource.text = "Some new text to create a journal"
        resource.save!
      end

      context 'with the user having registered for all notifications' do
        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason_ian: false,
              read_mail: false,
              reason_mail: :subscribed,
              read_mail_digest: nil,
              reason_mail_digest: false
            }
          end
        end
      end

      context 'with the user having registered for involved notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: true)),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true)),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for no notifications' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and watching the wiki' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        before do
          wiki.watcher_users << recipient
        end

        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason_ian: false,
              read_mail: false,
              reason_mail: :watched,
              read_mail_digest: nil,
              reason_mail_digest: false
            }
          end
        end
      end

      context 'with the user not having registered for watcher notifications and watching the wiki' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
          ]
        end

        before do
          wiki.watcher_users << recipient
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and not watching the wiki nor the page' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for watcher notifications and watching the page' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true)),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true))
          ]
        end

        before do
          wiki_page.watcher_users << recipient
        end

        it_behaves_like 'creates notification' do
          let(:notification_channel_reasons) do
            {
              read_ian: nil,
              reason_ian: false,
              read_mail: false,
              reason_mail: :watched,
              read_mail_digest: nil,
              reason_mail_digest: false
            }
          end
        end
      end

      context 'with the user not having registered for watcher notifications and watching the page' do
        let(:recipient_notification_settings) do
          [
            FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
            FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
          ]
        end

        before do
          wiki_page.watcher_users << recipient
        end

        it_behaves_like 'creates no notification'
      end

      context 'with the user having registered for all notifications but lacking permissions' do
        let(:permissions) { [] }

        it_behaves_like 'creates no notification'
      end
    end
  end
end
