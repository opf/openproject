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

DEVELOPER_PERMISSIONS = [:view_messages, :delete_own_messages, :edit_own_messages, :add_project, :edit_project, :select_project_modules, :manage_members, :manage_versions, :manage_categories, :view_work_packages, :add_work_packages, :edit_work_packages, :manage_work_package_relations, :manage_subtasks, :add_work_package_notes, :move_work_packages, :delete_work_packages, :view_work_package_watchers, :add_work_package_watchers, :delete_work_package_watchers, :manage_public_queries, :save_queries, :view_gantt, :view_calendar, :log_time, :view_time_entries, :edit_time_entries, :delete_time_entries, :manage_news, :comment_news, :view_documents, :manage_documents, :view_wiki_pages, :export_wiki_pages, :view_wiki_edits, :edit_wiki_pages, :delete_wiki_pages_attachments, :protect_wiki_pages, :delete_wiki_pages, :rename_wiki_pages, :add_messages, :edit_messages, :delete_messages, :manage_boards, :view_files, :manage_files, :browse_repository, :manage_repository, :view_changesets, :manage_project_activities, :export_work_packages]

describe MailHandler, type: :model do
  let(:anno_user) { User.anonymous }
  let(:project) { FactoryGirl.create(:valid_project, identifier: 'onlinestore', name: 'OnlineStore', is_public: false) }
  let(:priority_low)    { FactoryGirl.create(:priority_low, is_default: true) }


  before do
    allow(Setting).to receive(:notified_events).and_return(Redmine::Notifiable.all.map(&:name))
    # we need both of these run first so the anonymous user is created and
    # there is a default work package priority to save any work packages
    priority_low
    anno_user
  end

  after do
    User.current = nil
  end

  it 'should add a work_package by create user on public project' do
    allow(Setting).to receive(:default_language).and_return('en')
    Role.non_member.update_attribute :permissions, [:add_work_packages]
    project.update_attribute :is_public, true
    expect {
      work_package = submit_email('ticket_by_unknown_user.eml', issue: { project: 'onlinestore' }, unknown_user: 'create')
      work_package_created(work_package)
      expect(work_package.author.active?).to be_truthy
      expect(work_package.author.mail).to eq('john.doe@somenet.foo')
      expect(work_package.author.firstname).to eq('John')
      expect(work_package.author.lastname).to eq('Doe')

      # account information
      email = ActionMailer::Base.deliveries.first
      expect(email).not_to be_nil
      expect(email.subject).to eq(I18n.t('mail_subject_register', value: Setting.app_title))
      login = email.body.encoded.match(/\* Login: (\S+)\s?$/)[1]
      password = email.body.encoded.match(/\* Password: (\S+)\s?$/)[1]

      # Can't log in here since randomly assigned password must be changed
      found_user = User.find_by_login(login)
      expect(work_package.author).to eq(found_user)
      expect(found_user.check_password?(password)).to be_truthy
    }.to change(User, :count).by(1)
  end

  describe '#cleanup_body' do
    let(:input) { "Subject:foo\nDescription:bar\n" \
                  ">>> myserver.example.org 2016-01-27 15:56 >>>\n... (Email-Body) ..." }
    let(:handler) { MailHandler.send :new }

    context 'with regex delimiter' do
      before do
        allow(Setting).to receive(:mail_handler_body_delimiter_regex).and_return('>>>.+?>>>.*')
        allow(handler).to receive(:plain_text_body).and_return(input)
        expect(handler).to receive(:cleaned_up_text_body).and_call_original
      end

      it 'removes the irrelevant lines' do
        expect(handler.send(:cleaned_up_text_body)).to eq("Subject:foo\nDescription:bar")
      end
    end
  end

  private

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'

  def submit_email(filename, options = {})
    raw = IO.read(File.join(FIXTURES_PATH, filename))
    MailHandler.receive(raw, options)
  end

  def work_package_created(work_package)
    expect(work_package.is_a?(WorkPackage)).to be_truthy
    expect(work_package).not_to be_new_record
    work_package.reload
  end
end
