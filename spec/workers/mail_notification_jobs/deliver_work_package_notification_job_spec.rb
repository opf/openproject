#-- encoding: UTF-8
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

describe DeliverWorkPackageNotificationJob, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
  let(:recipient) {
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  }
  let(:author) { FactoryBot.create(:user) }
  let(:work_package) {
    FactoryBot.create(:work_package,
                       project: project,
                       author: author)
  }
  let(:journal) { work_package.journals.first }
  let(:instance) { described_class.new }
  subject { instance.perform(journal.id, recipient.id, author.id) }

  before do
    # make sure no actual calls make it into the UserMailer
    allow(UserMailer).to receive(:work_package_added).and_return(double('mail', deliver_now: nil))
    allow(UserMailer).to receive(:work_package_updated).and_return(double('mail', deliver_now: nil))
  end

  it 'sends a mail' do
    expect(UserMailer)
      .to receive(:work_package_added)
      .with(recipient, an_instance_of(Journal::AggregatedJournal), author)
    subject
  end

  context 'non-existant journal' do
    before do
      journal.destroy
    end

    it 'sends no mail' do
      expect(UserMailer).not_to receive(:work_package_added)
      subject
    end
  end

  context 'non-existant author' do
    before do
      author.destroy
    end

    it 'sends a mail' do
      expect(UserMailer).to receive(:work_package_added)
      subject
    end

    it 'uses the deleted user as author' do
      expect(UserMailer)
        .to receive(:work_package_added)
        .with(anything, anything, DeletedUser.first)

      subject
    end
  end

  context 'outdated journal' do
    before do
      # make sure there is a later journal, that supersedes the original one
      work_package.subject = 'changed subject'
      work_package.save!
    end

    it 'raises no observable error' do
      expect { subject }.not_to raise_error
    end
  end

  context 'update journal' do
    let(:journal) { work_package.journals.last }

    before do
      work_package.add_journal(FactoryBot.create(:user), 'a comment')
      work_package.save!
    end

    it 'sends an update mail' do
      expect(UserMailer).to receive(:work_package_updated)
      subject
    end

    it 'sends a mail for the aggregated journal' do
      expected = Journal::AggregatedJournal.aggregated_journals(journable: work_package).last
      expect(UserMailer).to receive(:work_package_updated) do |_recipient, journal, _author|
        expect(journal.id).to eq expected.id
        expect(journal.notes_id).to eq expected.notes_id

        double('mail', deliver_now: nil)
      end
      subject
    end
  end

  describe 'impersonation' do
    describe 'the recipient should become the current user during mail creation' do
      before do
        expect(UserMailer).to receive(:work_package_added) do
          expect(User.current).to eql(recipient)
          double('mail', deliver_now: nil)
        end
      end

      it { subject }
    end

    context 'for a known current user' do
      let(:current_user) { FactoryBot.create(:user) }

      it 'resets to the previous current user after running' do
        User.current = current_user
        subject
        expect(User.current).to eql(current_user)
      end
    end
  end

  describe 'exceptions during delivery' do
    before do
      mail = double('mail')
      allow(mail).to receive(:deliver_now).and_raise(SocketError)
      expect(UserMailer).to receive(:work_package_added).and_return(mail)
    end

    it 'raises the error' do
      expect { subject }.to raise_error(SocketError)
    end
  end

  describe 'exceptions during rendering' do
    before do
      expect(UserMailer).to receive(:work_package_added).and_raise('not today!')
    end

    it 'swallows the error' do
      expect { subject }.not_to raise_error
    end
  end
end
