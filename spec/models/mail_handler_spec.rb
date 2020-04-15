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

DEVELOPER_PERMISSIONS = [:view_messages, :delete_own_messages, :edit_own_messages, :add_project, :edit_project, :select_project_modules, :manage_members, :manage_versions, :manage_categories, :view_work_packages, :add_work_packages, :edit_work_packages, :manage_work_package_relations, :manage_subtasks, :add_work_package_notes, :move_work_packages, :delete_work_packages, :view_work_package_watchers, :add_work_package_watchers, :delete_work_package_watchers, :manage_public_queries, :save_queries, :view_gantt, :view_calendar, :log_time, :view_time_entries, :edit_time_entries, :delete_time_entries, :manage_news, :comment_news, :view_documents, :manage_documents, :view_wiki_pages, :export_wiki_pages, :view_wiki_edits, :edit_wiki_pages, :delete_wiki_pages_attachments, :protect_wiki_pages, :delete_wiki_pages, :rename_wiki_pages, :add_messages, :edit_messages, :delete_messages, :manage_forums, :view_files, :manage_files, :browse_repository, :manage_repository, :view_changesets, :manage_project_activities, :export_work_packages]

describe MailHandler, type: :model do
  let(:anno_user) { User.anonymous }
  let(:project) { FactoryBot.create(:valid_project, identifier: 'onlinestore', name: 'OnlineStore', public: false) }
  let(:public_project) { FactoryBot.create(:valid_project, identifier: 'onlinestore', name: 'OnlineStore', public: true) }
  let(:priority_low) { FactoryBot.create(:priority_low, is_default: true) }

  before do
    allow(Setting).to receive(:notified_events).and_return(Redmine::Notifiable.all.map(&:name))
    # we need both of these run first so the anonymous user is created and
    # there is a default work package priority to save any work packages
    priority_low
    anno_user
  end

  after do
    User.current = nil
    allow(Setting).to receive(:default_language).and_return('en')
  end

  shared_context 'wp_on_given_project' do
    let(:permissions) { %i[add_work_packages assign_versions] }
    let!(:user) do
      FactoryBot.create(:user,
                        mail: 'JSmith@somenet.foo',
                        firstname: 'John',
                        lastname: 'Smith',
                        member_in_project: project,
                        member_with_permissions: permissions)
    end
    let(:submit_options) { {} }

    subject do
      submit_email('wp_on_given_project.eml', **submit_options)
    end
  end

  shared_context 'wp_on_given_project_case_insensitive' do
    let(:permissions) { %i[add_work_packages assign_versions] }
    let!(:user) do
      FactoryBot.create(:user,
                        mail: 'JSmith@somenet.foo',
                        firstname: 'John',
                        lastname: 'Smith',
                        member_in_project: project,
                        member_with_permissions: permissions)
    end
    let(:submit_options) { {allow_override: 'version'} }

    subject do
      submit_email('wp_on_given_project_case_insensitive.eml', **submit_options)
    end
  end

  shared_context 'wp_update_with_quoted_reply_above' do
    let(:permissions) { %i[edit_work_packages view_work_packages] }
    let!(:user) do
      FactoryBot.create(:user,
                        mail: 'JSmith@somenet.foo',
                        member_in_project: project,
                        member_with_permissions: permissions)
    end

    let!(:work_package) do
      FactoryBot.create(:work_package, id: 2, project: project)
    end

    subject do
      submit_email('wp_update_with_quoted_reply_above.eml')
    end
  end

  shared_context 'wp_update_with_multiple_quoted_reply_above' do
    let(:permissions) { %i[edit_work_packages view_work_packages] }
    let!(:user) do
      FactoryBot.create(:user,
                        mail: 'JSmith@somenet.foo',
                        member_in_project: project,
                        member_with_permissions: permissions)
    end

    let!(:work_package) do
      FactoryBot.create(:work_package, id: 2, project: project)
    end

    subject do
      submit_email('wp_update_with_multiple_quoted_reply_above.eml')
    end
  end

  describe '#receive' do
    shared_examples_for 'work package created' do
      it 'creates the work package' do
        expect(subject)
          .to be_a(WorkPackage)

        expect(subject)
          .to be_persisted
      end
    end

    shared_examples_for 'journal created' do
      it 'creates the journal' do
        expect(subject)
          .to be_a(Journal)

        expect(subject)
          .to be_persisted
      end
    end

    context 'create work package' do
      context 'in a given project' do
        let!(:status) { FactoryBot.create(:status, name: 'Resolved') }
        let!(:version) { FactoryBot.create(:version, name: 'alpha', project: project) }

        include_context 'wp_on_given_project' do
          let(:submit_options) { { allow_override: 'version' } }
        end

        it_behaves_like 'work package created'

        it 'sets the referenced project' do
          expect(subject.project)
            .to eql(project)
        end

        it 'sets the first type in the project' do
          expect(subject.type)
            .to eql(project.types.first)
        end

        it 'sets the subject' do
          expect(subject.subject)
            .to eql('New ticket on a given project')
        end

        it 'sets the sender as the author' do
          expect(subject.author)
            .to eql(user)
        end

        it 'set the description' do
          expect(subject.description)
            .to include('Lorem ipsum dolor sit amet, consectetuer adipiscing elit.')
        end

        it 'sets the start date' do
          expect(subject.start_date.to_s)
            .to eql('2010-01-01')
        end

        it 'sets the due date' do
          expect(subject.due_date.to_s)
            .to eql('2010-12-31')
        end

        it 'sets the assignee' do
          expect(subject.assigned_to)
            .to eql(user)
        end

        it 'sets the status' do
          expect(subject.status)
            .to eql(status)
        end

        it 'sets the version' do
          expect(subject.version)
            .to eql(version)
        end

        it 'sets the estimated_hours' do
          expect(subject.estimated_hours)
            .to eql(2.5)
        end

        it 'sets the done_ratio' do
          expect(subject.done_ratio)
            .to eql(30)
        end

        it 'removes keywords' do
          expect(subject.description)
            .not_to match(/^Project:/i)

          expect(subject.description)
            .not_to match(/^Status:/i)

          expect(subject.description)
            .not_to match(/^Start Date:/i)
        end

        context 'with a user watching every creation' do
          let!(:other_user) do
            FactoryBot.create(:user,
                              mail_notification: 'all',
                              member_in_project: project,
                              member_with_permissions: %i[view_work_packages])
          end

          it 'sends a mail as a work package has been created' do
            subject

            # Email notification should be sent
            perform_enqueued_jobs
            mail = ActionMailer::Base.deliveries.last

            expect(mail)
              .not_to be_nil
            expect(mail.subject)
              .to include('New ticket on a given project')
          end
        end
      end

      context 'in given project with a default type' do
        let(:default_type) do
          FactoryBot.create(:type, is_default: true).tap do |t|
            project.types << t
          end
        end

        include_context 'wp_on_given_project' do
          let(:submit_options) { {issue: {type: default_type.name}} }
        end

        it_behaves_like 'work package created'

        it 'sets the default type' do
          expect(subject.type.name)
            .to eql(default_type.name)
        end
      end

      context 'email by unknown user' do
        it 'adds a work_package by create user on public project' do
          Role.non_member.update_attribute :permissions, [:add_work_packages]
          project.update_attribute :public, true
          expect do
            work_package = submit_email('ticket_by_unknown_user.eml', issue: {project: 'onlinestore'}, unknown_user: 'create')
            work_package_created(work_package)
            expect(work_package.author.active?).to be_truthy
            expect(work_package.author.mail).to eq('john.doe@somenet.foo')
            expect(work_package.author.firstname).to eq('John')
            expect(work_package.author.lastname).to eq('Doe')

            # account information
            perform_enqueued_jobs

            email = ActionMailer::Base.deliveries.first
            expect(email).not_to be_nil
            expect(email.subject).to eq(I18n.t('mail_subject_register', value: Setting.app_title))
            login = email.body.encoded.match(/\* Username: (\S+)\s?$/)[1]
            password = email.body.encoded.match(/\* Password: (\S+)\s?$/)[1]

            # Can't log in here since randomly assigned password must be changed
            found_user = User.find_by_login(login)
            expect(work_package.author).to eq(found_user)
            expect(found_user.check_password?(password)).to be_truthy
          end.to change(User, :count).by(1)
        end

        it 'rejects if unknown_user=accept and permission check is present' do
          expected =
            'MailHandler: work_package could not be created by Anonymous due to ' \
          '#["may not be accessed.", "Type was attempted to be written but is not writable.", ' \
          '"Project was attempted to be written but is not writable.", ' \
          '"Subject was attempted to be written but is not writable.", ' \
          '"Description was attempted to be written but is not writable."]'

          expect(Rails.logger)
            .to receive(:error)
            .with(expected)

          result = submit_email 'ticket_by_unknown_user.eml',
                                issue: { project: project.identifier },
                                unknown_user: 'accept'

          expect(result).to eq false
        end

        it 'accepts if unknown_user=accept and no_permission_check' do
          work_package = submit_email 'ticket_by_unknown_user.eml',
                                      issue: { project: project.identifier },
                                      unknown_user: 'accept',
                                      no_permission_check: 1

          work_package_created(work_package)
          expect(work_package.author).to eq(User.anonymous)
        end
      end

      context 'email from emission address', with_settings: {mail_from: 'openproject@example.net'} do
        before do
          Role.non_member.add_permission!(:add_work_packages)
        end

        subject do
          submit_email('ticket_from_emission_address.eml',
                       issue: {project: public_project.identifier},
                       unknown_user: 'create')
        end

        it 'returns false' do
          expect(subject).to be_falsey
        end

        it 'does not create the user' do
          expect { subject }
            .not_to(change { User.count })
        end

        it 'does not create the work_package' do
          expect { subject }
            .not_to(change { WorkPackage.count })
        end
      end

      context 'wp with status' do
        let!(:status) { FactoryBot.create(:status, name: 'Resolved') }

        # This email contains: 'Project: onlinestore' and 'Status: Resolved'
        include_context 'wp_on_given_project'

        it_behaves_like 'work package created'

        it 'assigns the status to the created work package' do
          expect(subject.status)
            .to eql(status)
        end
      end

      context 'wp with status case insensitive' do
        let!(:status) { FactoryBot.create(:status, name: 'Resolved') }
        let!(:priority_low) { FactoryBot.create(:priority_low, name: 'Low', is_default: true) }
        let!(:version) { FactoryBot.create(:version, name: 'alpha', project: project) }

        # This email contains: 'Project: onlinestore' and 'Status: resolved'
        include_context 'wp_on_given_project_case_insensitive'

        it_behaves_like 'work package created'

        it 'assigns the status to the created work package' do
          expect(subject.status).to eq(status)
          expect(subject.version).to eq(version)
          expect(subject.priority).to eq priority_low
        end
      end
    end

    describe 'update work package' do
      let!(:mail_user) { FactoryBot.create :admin, mail: 'user@example.org' }
      let!(:work_package) { FactoryBot.create :work_package, project: project }

      before do
        # Avoid trying to extract text
        allow(OpenProject::Database).to receive(:allows_tsv?).and_return false
      end

      it 'should update a work package with attachment' do
        expect(WorkPackage).to receive(:find_by).with(id: 123).and_return(work_package)

        # Mail with two attachemnts, one of which is skipped by signature.asc filename match
        submit_email 'update_ticket_with_attachment_and_sig.eml', issue: {project: 'onlinestore'}

        work_package.reload

        # Expect comment
        expect(work_package.journals.last.notes).to eq 'Reply to work package #123'
        expect(work_package.journals.last.user).to eq mail_user

        # Expect filename without signature to be saved
        expect(work_package.attachments.count).to eq(1)
        expect(work_package.attachments.first.filename).to eq('Photo25.jpg')
      end

      context 'with existing attachment' do
        let!(:attachment) { FactoryBot.create(:attachment, container: work_package) }

        it 'does not replace it (Regression #29722)' do
          work_package.reload
          expect(WorkPackage).to receive(:find_by).with(id: 123).and_return(work_package)

          # Mail with two attachemnts, one of which is skipped by signature.asc filename match
          submit_email 'update_ticket_with_attachment_and_sig.eml', issue: {project: 'onlinestore'}

          expect(work_package.attachments.length).to eq 2
        end
      end

      context 'with a custom field' do
        let(:work_package) { FactoryBot.create :work_package, project: project }
        let(:type) { FactoryBot.create :type }

        before do
          type.custom_fields << custom_field
          type.save!

          allow_any_instance_of(WorkPackage).to receive(:available_custom_fields).and_return([custom_field])

          expect(WorkPackage).to receive(:find_by).with(id: 42).and_return(work_package)
          expect(User).to receive(:find_by_mail).with("h.wurst@openproject.com").and_return(mail_user)
        end

        context 'of type text' do
          let(:custom_field) { FactoryBot.create :text_wp_custom_field, name: "Notes" }

          before do
            submit_email 'work_package_with_text_custom_field.eml', issue: {project: project.identifier}

            work_package.reload
          end

          it "sets the value" do
            value = work_package.custom_values.where(custom_field_id: custom_field.id).pluck(:value).first

            expect(value).to eq "some text" # as given in .eml fixture
          end
        end

        context 'of type list' do
          let(:custom_field) { FactoryBot.create :list_wp_custom_field, name: "Letters", possible_values: %w(A B C) }

          before do
            submit_email 'work_package_with_list_custom_field.eml', issue: {project: project.identifier}

            work_package.reload
          end

          it "sets the value" do
            option = CustomOption.where(custom_field_id: custom_field.id, value: "B").first # as given in .eml fixture
            value = work_package.custom_values.where(custom_field_id: custom_field.id).pluck(:value).first

            expect(value).to eq option.id.to_s
          end
        end
      end
    end

    context 'truncate emails based on the Setting' do
      context 'with no setting', with_settings: {mail_handler_body_delimiters: ''} do
        include_context 'wp_on_given_project'

        it_behaves_like 'work package created'

        it 'adds the entire email into the work_package' do
          expect(subject.description)
            .to include('---')

          expect(subject.description)
            .to include('This paragraph is after the delimiter')
        end
      end

      context 'with a single string', with_settings: {mail_handler_body_delimiters: '---'} do
        include_context 'wp_on_given_project'

        it_behaves_like 'work package created'

        it 'truncates the email at the delimiter for the work package' do
          expect(subject.description)
            .to include('This paragraph is before delimiters')

          expect(subject.description)
            .to include('--- This line starts with a delimiter')

          expect(subject.description)
            .not_to match(/^---$/)

          expect(subject.description)
            .not_to include('This paragraph is after the delimiter')
        end
      end

      context 'with a single quoted reply (e.g. reply to a OpenProject email notification)',
              with_settings: {mail_handler_body_delimiters: '--- Reply above. Do not remove this line. ---'} do
        include_context 'wp_update_with_quoted_reply_above'

        it_behaves_like 'journal created'

        it 'truncates the email at the delimiter with the quoted reply symbols (>)' do
          expect(subject.notes)
            .to include('An update to the issue by the sender.')

          expect(subject.notes)
            .not_to match(Regexp.escape('--- Reply above. Do not remove this line. ---'))

          expect(subject.notes)
            .not_to include('Looks like the JSON api for projects was missed.')
        end
      end

      context 'with multiple quoted replies (e.g. reply to a reply of a Redmine email notification)',
              with_settings: {mail_handler_body_delimiters: '--- Reply above. Do not remove this line. ---'} do
        include_context 'wp_update_with_quoted_reply_above'

        it_behaves_like 'journal created'

        it 'truncates the email at the delimiter with the quoted reply symbols (>)' do
          expect(subject.notes)
            .to include('An update to the issue by the sender.')

          expect(subject.notes)
            .not_to match(Regexp.escape('--- Reply above. Do not remove this line. ---'))

          expect(subject.notes)
            .not_to include('Looks like the JSON api for projects was missed.')
        end
      end

      context 'with multiple strings',
              with_settings: {mail_handler_body_delimiters: "---\nBREAK"} do
        include_context 'wp_on_given_project'

        it_behaves_like 'work package created'

        it 'truncates the email at the first delimiter found (BREAK)' do
          expect(subject.description)
            .to include('This paragraph is before delimiters')

          expect(subject.description)
            .not_to include('BREAK')

          expect(subject.description)
            .not_to include('This paragraph is between delimiters')

          expect(subject.description)
            .not_to match(/^---$/)

          expect(subject.description)
            .not_to include('This paragraph is after the delimiter')
        end
      end
    end

    describe 'category' do
      let!(:category) { FactoryBot.create :category, project: project, name: 'Foobar' }

      it 'should add a work_package with category' do
        allow(Setting).to receive(:default_language).and_return('en')
        Role.non_member.update_attribute :permissions, [:add_work_packages]
        project.update_attribute :public, true

        work_package = submit_email 'ticket_with_category.eml',
                                    issue: {project: 'onlinestore'},
                                    allow_override: ['category'],
                                    unknown_user: 'create'
        work_package_created(work_package)
        expect(work_package.category).to eq(category)
      end
    end
  end

  describe '#cleanup_body' do
    let(:input) do
      "Subject:foo\nDescription:bar\n" \
      ">>> myserver.example.org 2016-01-27 15:56 >>>\n... (Email-Body) ..."
    end
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
