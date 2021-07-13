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

describe Notifications::JournalCompletedJob, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:permissions) { [:view_work_packages] }
  let(:recipient) do
    FactoryBot.create(:user, member_in_project: project, member_with_permissions: permissions, login: "johndoe")
  end
  let(:author) { FactoryBot.create(:user, login: "marktwain") }
  let(:send_mail) { true }

  subject { described_class.new.perform(journal.id, send_mail) }

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing
  end

  context 'for work packages' do
    let(:work_package) do
      FactoryBot.create(:work_package,
                        project: project,
                        author: author,
                        assigned_to: recipient)
    end
    let(:journal) { journal_1 }
    let(:journal_1) { work_package.journals.first }
    let(:journal_2) do
      work_package.add_journal author, 'something I have to say'
      work_package.save(validate: false)
      work_package.journals.last
    end

    shared_examples_for 'sends notification' do
      it 'sends a notification' do
        expect(OpenProject::Notifications)
          .to receive(:send)
          .with(OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY,
                journal: an_instance_of(Journal),
                send_mail: send_mail)

        subject
      end
    end

    shared_examples_for 'sends no notification' do
      it 'sends no notification' do
        expect(OpenProject::Notifications)
          .not_to receive(:send)

        subject
      end
    end

    it_behaves_like 'sends notification'

    context 'non-existant journal' do
      before do
        journal.destroy
      end

      it_behaves_like 'sends no notification'
    end

    describe 'journal creation' do
      context 'work_package_created' do
        before do
          FactoryBot.create(:work_package, project: project)
        end

        it_behaves_like 'sends notification'
      end

      context 'work_package_updated' do
        before do
          work_package.add_journal(author)
          work_package.subject = 'A change to the issue'
          work_package.save!(validate: false)
        end

        it_behaves_like 'sends notification'
      end

      context 'work_package_note_added' do
        before do
          work_package.add_journal(author, 'This update has a note')
          work_package.save!(validate: false)
        end

        it_behaves_like 'sends notification'
      end
    end
  end

  context 'for wiki page content' do
    let(:wiki_page_content) do
      wiki = FactoryBot.create(:wiki,
                               project: project)

      FactoryBot.create(:wiki_page_with_content, wiki: wiki).content
    end

    let(:journal) { journal_1 }
    let(:journal_1) { wiki_page_content.journals.first }
    let(:journal_2) do
      wiki_page_content.add_journal author, 'something I have to say'
      wiki_page_content.save(validate: false)
      wiki_page_content.journals.last
    end

    it 'sends a notification' do
      expect(OpenProject::Notifications)
        .to receive(:send)
        .with(OpenProject::Events::AGGREGATED_WIKI_JOURNAL_READY,
              journal: an_instance_of(Journal),
              send_mail: send_mail)

      subject
    end
  end
end
