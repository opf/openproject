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

describe Notifications::JournalWikiMailService do
  let(:project) do
    FactoryBot.build_stubbed(:project).tap do |p|
      allow(p)
        .to receive(:notified_users)
        .and_return([project_notified_user_with_permission, project_notified_user_wo_permission])
    end
  end
  let(:wiki) do
    FactoryBot.build_stubbed(:wiki, project: project).tap do |w|
      allow(w)
        .to receive(:watcher_recipients)
        .and_return([wiki_watcher_user])
    end
  end
  let(:wiki_page) do
    FactoryBot.build_stubbed(:wiki_page, wiki: wiki).tap do |w|
      allow(w)
        .to receive(:watcher_recipients)
        .and_return([wiki_page_watcher_user])
    end
  end
  let(:wiki_content) do
    FactoryBot.build_stubbed(:wiki_content, page: wiki_page).tap do |wc|
      allow(wc)
        .to receive(:visible?)
        .with(project_notified_user_with_permission)
        .and_return(true)

      allow(wc)
        .to receive(:visible?)
        .with(project_notified_user_wo_permission)
        .and_return(false)
    end
  end
  let(:journal) do
    FactoryBot.build_stubbed(:wiki_content_journal, journable: wiki_content, user: current_user).tap do |j|
      allow(j)
        .to receive(:initial?)
        .and_return(journal_initial)

      allow(j)
        .to receive(:noop?)
        .and_return(journal_noop)
    end
  end
  let(:journal_initial) { true }
  let(:journal_noop) { false }

  let(:notification_setting) { %w(wiki_content_added wiki_content_updated) }

  let(:current_user) do
    FactoryBot.build_stubbed(:user)
  end

  let(:project_notified_user_with_permission) do
    FactoryBot.build_stubbed(:user)
  end

  let(:project_notified_user_wo_permission) do
    FactoryBot.build_stubbed(:user)
  end

  let(:wiki_watcher_user) do
    FactoryBot.build_stubbed(:user)
  end

  let(:wiki_page_watcher_user) do
    FactoryBot.build_stubbed(:user)
  end

  context '.call' do
    let(:subject) { described_class.call(journal, send_mails) }
    let(:send_mails) { true }

    before do
      allow(Setting).to receive(:notified_events).and_return(notification_setting)
    end

    shared_examples_for 'sends no mails' do
      it 'sends no mails' do
        expect(UserMailer)
          .not_to receive(:wiki_content_updated)

        expect(UserMailer)
          .not_to receive(:wiki_content_added)

        subject
      end
    end

    context 'with the settings allowing email sending for newly added content' do
      let(:notification_setting) { %w(wiki_content_added) }

      context 'for an initial journal' do
        let(:journal_initial) { true }

        it 'sends mails to users listening on all changes and to watchers of the wiki' do
          [project_notified_user_with_permission, wiki_watcher_user].each do |u|
            mailer = double('mailer')

            expect(UserMailer)
              .to receive(:wiki_content_added)
              .with(u, wiki_content, current_user)
              .and_return(mailer)

            expect(mailer)
              .to receive(:deliver_later)
          end

          subject
        end

        context 'with send_mails set to false' do
          let(:send_mails) { false }

          it_behaves_like 'sends no mails'
        end

        context 'with perform_deliveries set to false' do
          before do
            allow(UserMailer)
              .to receive(:perform_deliveries)
              .and_return(false)
          end

          it_behaves_like 'sends no mails'
        end

        context 'with the journal being a noop' do
          let(:journal_noop) { true }

          it_behaves_like 'sends no mails'
        end
      end

      context 'for a non initial journal' do
        let(:journal_initial) { false }

        it_behaves_like 'sends no mails'
      end
    end

    context 'with the settings allowing email sending for updated content' do
      let(:notification_setting) { %w(wiki_content_updated) }

      context 'for a non initial journal' do
        let(:journal_initial) { false }

        it 'sends mails to users listening on all changes and to watchers of the wiki' do
          [project_notified_user_with_permission, wiki_watcher_user, wiki_page_watcher_user].each do |u|
            mailer = double('mailer')

            expect(UserMailer)
              .to receive(:wiki_content_updated)
              .with(u, wiki_content, current_user)
              .and_return(mailer)

            expect(mailer)
              .to receive(:deliver_later)
          end

          subject
        end

        context 'with send_mails set to false' do
          let(:send_mails) { false }

          it_behaves_like 'sends no mails'
        end

        context 'with perform_deliveries set to false' do
          before do
            allow(UserMailer)
              .to receive(:perform_deliveries)
              .and_return(false)
          end

          it_behaves_like 'sends no mails'
        end

        context 'with the journal being a noop' do
          let(:journal_noop) { true }

          it_behaves_like 'sends no mails'
        end
      end

      context 'for an initial journal' do
        let(:journal_initial) { true }

        it_behaves_like 'sends no mails'
      end
    end
  end

  it 'listener is subscribed' do
    journal = double('journal')
    send_mail = true

    expect(Notifications::JournalWikiMailService)
      .to receive(:call)
      .with(journal, send_mail)

    OpenProject::Notifications.send(OpenProject::Events::AGGREGATED_WIKI_JOURNAL_READY,
                                    journal: journal,
                                    send_mail: send_mail)
  end
end
