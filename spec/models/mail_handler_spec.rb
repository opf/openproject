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

require File.dirname(__FILE__) + '/../spec_helper'

FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'

DEVELOPER_PERMISSIONS = [:view_messages, :delete_own_messages, :edit_own_messages, :add_project, :edit_project, :select_project_modules, :manage_members, :manage_versions, :manage_categories, :view_work_packages, :add_work_packages, :edit_work_packages, :manage_work_package_relations, :manage_subtasks, :add_work_package_notes, :move_work_packages, :delete_work_packages, :view_work_package_watchers, :add_work_package_watchers, :delete_work_package_watchers, :manage_public_queries, :save_queries, :view_gantt, :view_calendar, :log_time, :view_time_entries, :edit_time_entries, :delete_time_entries, :manage_news, :comment_news, :view_documents, :manage_documents, :view_wiki_pages, :export_wiki_pages, :view_wiki_edits, :edit_wiki_pages, :delete_wiki_pages_attachments, :protect_wiki_pages, :delete_wiki_pages, :rename_wiki_pages, :add_messages, :edit_messages, :delete_messages, :manage_boards, :view_files, :manage_files, :browse_repository, :manage_repository, :view_changesets, :manage_project_activities, :export_work_packages]

describe MailHandler, type: :model do
  # TODO: (a big one) the test setup to get a general project one can work with should be improved a lot
  # let(:user)    { FactoryGirl.build(:user, :mail => "JSmith@somenet.foo", :mail_notification => "all", :lastname => "Smith", :firstname => "John", :login => "jsmith") }
  # let(:user2)   { FactoryGirl.build(:user, :mail => "dlopper@somenet.foo", :mail_notification => "all", :lastname => "Lopper", :firstname => "Dave", :login => "dlopper") }
  let(:anno_user) { User.anonymous }
  let(:project) { FactoryGirl.create(:valid_project, identifier: 'onlinestore', name: 'OnlineStore', is_public: false) }
  # let(:role)    { FactoryGirl.create(:role, :permissions => DEVELOPER_PERMISSIONS, :name => "Developer") }

  # let(:member)  { FactoryGirl.build(:member, :project => project,
  #                                        :roles => [role],
  #                                        :principal => user) }
  # let(:member2)  { FactoryGirl.build(:member, :project => project,
  #                                        :roles => [role],
  #                                        :principal => user2) }
  # let(:status_open)     {project.types.third.statuses.first}
  # let(:status_resolved) {project.types.third.statuses.second}
  # let(:workflow)        {project.types.third.workflows.first}
  # let(:type_support) {project.types.second}
  # let(:type_feature) {project.types.third}
  let(:priority_low)    { FactoryGirl.create(:priority_low, is_default: true) }
  # let(:priority_high)   {FactoryGirl.create(:priority_high)}
  # let(:priority_urgent) {FactoryGirl.create(:priority_urgent)}
  # let(:version_a)       {FactoryGirl.create(:version, :name => 'alpha', :description => "Private Alpha", :project => project)}
  # let(:version_b)       {FactoryGirl.create(:version, :name => 'beta', :description => "Private beta", :project => project)}
  # let(:cat_stock_man)   {FactoryGirl.create(:issue_category, :name => "Stock management", :assigned_to => nil , :project => project)}

  # let(:existing_work_package)  {FactoryGirl.create(:work_package, :project => project, :id => 2,:type => type_support, :author => user, :subject => "Add ingredients categories", :description => "Ingredients of the recipe should be classified by categories")}
  # let(:project_board)   {FactoryGirl.create(:board, :project => project)}
  # let(:message_1) {FactoryGirl.create(:message, :id =>1, :subject => "First post", :content => "This is the very first post\n\ in the forum",:author_id => user.id, :parent_id => nil, :board => project_board)}
  # let(:message_2) {FactoryGirl.create(:message, :id =>2, :subject => "First reply", :content => "Reply to the first post",:author_id => user2.id, :parent_id => 1, :board => project_board)}
  # let(:message_3) {FactoryGirl.create(:message, :id =>3, :subject => "RE: First post", :content => "An other reply",:author_id => user.id, :parent_id => 1, :board => project_board)}
  # let(:a_custom_field) {FactoryGirl.create(:work_package_custom_field)}

  before do
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Redmine::Notifiable.all.map(&:name)
    # we need both of these run first so the anonymous user is created and
    # there is a default work package priority to save any work packages
    priority_low
    anno_user
    # TODO: these a inherently part of the test setup
    # [user, user2, member, member2, priority_low, priority_high, priority_urgent, version_a, version_b, anno_user, message_1, message_2, message_3, a_custom_field].map(&:save!)
    #  status_open.update_attribute :name, "Open"
    #  status_resolved.update_attribute :name, "Resolved"
    #  workflow.role = role
    #  workflow.save!
    #  type_support.update_attribute :name, "Support"
    #  type_feature.update_attribute :name, "Feature"
    #  cat_stock_man.save
    #  project.issue_categories << cat_stock_man
    #  project.save!
    #  existing_work_package.priority = priority_low
    #  existing_work_package.save!
  end

  after do
    User.current = nil
  end

  # it "should add an work_package" do
  #   ActionMailer::Base.deliveries.clear
  #   work_package = submit_email('ticket_on_given_project.eml', {:allow_override => ['fixed_version']})
  #   work_package_created(work_package)
  #   work_package.project.should == project
  #   work_package.project.types.first.should == work_package.type
  #   work_package.subject.should == "New ticket on a given project"
  #   work_package.author.should == user
  #   work_package.status.should == status_resolved
  #   work_package.description.should match(/^Lorem ipsum dolor sit amet, consectetuer adipiscing elit./)
  #   work_package.start_date.to_s.should == '2010-01-01'
  #   work_package.due_date.to_s.should == '2010-12-31'
  #   work_package.assigned_to.should == user
  #   work_package.fixed_version.should == version_a
  #   work_package.estimated_hours.should == 2.5
  #   work_package.done_ratio.should == 30
  #   work_package.root_id.should == work_package.id
  #   # keywords should be removed from the email body
  #   work_package.description.should_not match(/^Project:/i)
  #   work_package.description.should_not match(/^Status:/i)
  #   work_package.description.should_not match(/^Start Date:/i)
  #   # Email notification should be sent
  #   mail = ActionMailer::Base.deliveries.last
  #   mail.should_not be_nil
  #   mail.subject.should include('New ticket on a given project')
  # end

  # it "should add an work_package with default type" do
  #   work_package = submit_email('ticket_on_given_project.eml', :work_package => {'type' => 'Support'})
  #   work_package_created(work_package)
  #   work_package.type.name.should == type_support.name
  # end

  # it "should add an work_package with status" do
  #   work_package = submit_email('ticket_on_given_project.eml')
  #   work_package_created(work_package)
  #   work_package.project.should == project
  #   work_package.status.should == status_resolved
  # end

  # context "fixed version" do
  #   it "should add an work_package without version if no version and no fixed version given" do
  #     work_package = submit_email('ticket_on_given_project_without_version.eml')
  #     work_package_created(work_package)
  #     work_package.project.should == project
  #     work_package.fixed_version.should == nil
  #   end

  #   it "should add an work_package with version if no version given but fixed version present" do
  #     work_package = submit_email('ticket_on_given_project_without_version.eml', {:work_package => {'fixed_version' => version_a.name}})
  #     work_package_created(work_package)
  #     work_package.project.should == project
  #     work_package.fixed_version.should == version_a
  #   end

  #   it "should add an work_package with fixed version if different version given but not allowed to override" do
  #     work_package = submit_email('ticket_on_given_project_with_different_version_then_fixed.eml', {:work_package => {'fixed_version' => version_a.name}})
  #     work_package_created(work_package)
  #     work_package.project.should == project
  #     work_package.fixed_version.should == version_a
  #   end

  #   it "should add an work_package with given version if fixed version present but allowed to override" do
  #     work_package = submit_email('ticket_on_given_project_with_different_version_then_fixed.eml', {:work_package => {'fixed_version' => version_a.name}, :allow_override => ['fixed_version']})
  #     work_package_created(work_package)
  #     work_package.project.should == project
  #     work_package.fixed_version.should == version_b
  #   end
  # end

  # it "should add an work_package with attributes override" do
  #   work_package = submit_email('ticket_with_attributes.eml', {:allow_override => 'type,category,priority'})
  #   work_package_created(work_package)
  #   work_package.subject.should == "New ticket on a given project"
  #   work_package.author.should == user
  #   work_package.project.should == project
  #   work_package.type.to_s.should ==  type_feature.name
  #   work_package.category.to_s.should == cat_stock_man.name
  #   work_package.priority.to_s.should == priority_urgent.name
  #   work_package.description.should match(/^Lorem ipsum dolor sit amet, consectetuer adipiscing elit./)
  # end

  # it "should add an work_package with partial attributes override" do
  #   work_package = submit_email('ticket_with_attributes.eml', {:work_package => {'priority' => 'High'}, :allow_override => ['type']})
  #   work_package_created(work_package)
  #   work_package.subject.should == "New ticket on a given project"
  #   work_package.author.should == user
  #   work_package.project.should == project
  #   work_package.type.to_s.should ==  type_feature.name
  #   work_package.category.should be_nil
  #   work_package.priority.to_s.should == priority_high.name
  #   work_package.description.should match(/^Lorem ipsum dolor sit amet, consectetuer adipiscing elit./)
  # end

  # it "should add an work_package with spaces between attribute and separator" do
  #   work_package = submit_email('ticket_with_spaces_between_attribute_and_separator.eml', {:allow_override => 'type,category,priority'})
  #   work_package_created(work_package)
  #   work_package.subject.should == "New ticket on a given project"
  #   work_package.author.should == user
  #   work_package.project.should == project
  #   work_package.type.to_s.should ==  type_feature.name
  #   work_package.category.to_s.should == cat_stock_man.name
  #   work_package.priority.to_s.should == priority_urgent.name
  #   work_package.description.should match(/^Lorem ipsum dolor sit amet, consectetuer adipiscing elit./)
  # end

  # it "should add an work_package with attachment to specific project" do
  #   work_package = submit_email('ticket_with_attachment.eml', {:work_package => {'project' => 'onlinestore'}})
  #   work_package_created(work_package)
  #   work_package.subject.should == "Ticket created by email with attachment"
  #   work_package.author.should == user
  #   work_package.project.should == project
  #   work_package.description.should == "This is  a new ticket with attachments"
  #   # Attachment properties
  #   work_package.attachments.first.filename.should == 'Paella.jpg'
  #   work_package.attachments.first.content_type.should == 'image/jpeg'
  #   work_package.attachments.first.filesize.should == 10790
  # end

  # it "should add an work_package with custom_fields" do
  #   pending
  #   work_package = submit_email('ticket_with_custom_fields.eml', {:work_package => {'project' => 'onlinestore'}})
  #   work_package_created(work_package)
  #   work_package.subject.should == "New ticket with custom field values"
  #   work_package.custom_value_for(CustomField.find_by_name('Searchable field')).value.should == 'Value for a custom field'
  #   work_package.description.should_not match(/^searchable field:/i)
  # end

  # it "should add an work_package with cc" do
  #   work_package = submit_email('ticket_with_cc.eml', {:work_package => {'project' => 'onlinestore'}})
  #   work_package_created(work_package)
  #   work_package.subject.should == "New ticket on a given project"
  #   work_package.watched_by?(user2).should be_true
  #   work_package.watcher_user_ids.size.should == 1
  # end

  # it "should not add an work_package if a unknow user sends a mail on public project" do
  #   project.update_attribute :is_public, true
  #   lambda do
  #     submit_email('ticket_by_unknown_user.eml', {:work_package => {'project' => 'onlinestore'}}).should be_false
  #   end.should_not change(User, :count)
  # end

  # it "should add an work_package from anonymous user on public project" do
  #   project.update_attribute :is_public, true
  #   Role.anonymous.update_attribute :permissions, [:add_work_packages]
  #   lambda do
  #     work_package = submit_email('ticket_by_unknown_user.eml', {:work_package => {'project' => 'onlinestore'}, :unknown_user => 'accept'})
  #     work_package_created(work_package)
  #     work_package.author.anonymous?.should be_true
  #   end.should_not change(User, :count)
  # end

  # it "should add an work_package from anonymous user with no from address on public project" do
  #   project.update_attribute :is_public, true
  #   Role.anonymous.update_attribute :permissions, [:add_work_packages]
  #   lambda do
  #     work_package = submit_email('ticket_by_empty_user.eml', {:work_package => {'project' => 'onlinestore'}, :unknown_user => 'accept'})
  #     work_package_created(work_package)
  #     work_package.author.anonymous?.should be_true
  #   end.should_not change(User, :count)
  # end

  # it "should not add an work_package from anonymous user on private project" do
  #   project.is_public?.should be_false
  #   Role.anonymous.update_attribute :permissions, [:add_work_packages]
  #   lambda do
  #     lambda do
  #       submit_email('ticket_by_unknown_user.eml', {:work_package => {'project' => 'onlinestore'}, :unknown_user => 'accept'}).should be_false
  #     end.should_not change(WorkPackage, :count)
  #   end.should_not change(User, :count)
  # end

  # it "should add an work_package from anonymous user on private project with no_permission_check" do
  #   project.is_public?.should be_false
  #   lambda do
  #     lambda do
  #       work_package = submit_email('ticket_by_unknown_user.eml', {:work_package => {'project' => 'onlinestore'}, :no_permission_check => '1', :unknown_user => 'accept'})
  #       work_package_created(work_package)
  #       work_package.author.anonymous?.should be_true
  #       work_package.root_id.should == work_package.id
  #       work_package.project.is_public?.should be_false
  #       work_package.leaf?.should be_true
  #     end.should change(WorkPackage, :count).by(1)
  #   end.should_not change(User, :count)
  # end

  it 'should add a work_package by create user on public project' do
    ActionMailer::Base.deliveries.clear
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

  # it "should not add an work_package if from header is missing" do
  #   Role.anonymous.update_attribute :permissions, [:add_work_packages]
  #   submit_email('ticket_without_from_header.eml').should be_false
  # end

  # it "should add an work_package with invalid attributes" do
  #   work_package = submit_email('ticket_with_invalid_attributes.eml', {:allow_override => 'type,category,priority'})
  #   work_package_created(work_package)
  #   work_package.assigned_to.should be_nil
  #   work_package.start_date.should be_nil
  #   work_package.due_date.should be_nil
  #   work_package.done_ratio.should == 0
  #   work_package.priority.to_s.should == priority_low.name
  #   work_package.description.should match(/^Lorem ipsum dolor sit amet, consectetuer adipiscing elit./)
  # end

  # it "should add an work_package with localized attributes" do
  #   pending
  #   Setting.available_languages = [:en, :fr]
  #   user.update_attribute :language, 'fr'
  #   work_package = submit_email('ticket_with_localized_attributes.eml', {:allow_override => 'type,category,priority'})
  #   work_package_created(work_package)
  #   work_package.subject.should == "New ticket on a given project"
  #   work_package.author.should == user
  #   work_package.project.should == project
  #   work_package.type.to_s.should ==  type_feature.name
  #   work_package.category.to_s.should == cat_stock_man.name
  #   work_package.priority.to_s.should == priority_urgent.name
  #   work_package.description.should match(/^Lorem ipsum dolor sit amet, consectetuer adipiscing elit./)
  # end

  # it "should add an work_package with japanese_keywords" do
  #   pending
  #   type_j = type.create!(:name => '開発')
  #   project.types << type_j
  #   work_package = submit_email('japanese_keywords_iso_2022_jp.eml', {:allow_override => 'type'})
  #   work_package_created(work_package)
  #   work_package.type.should == type_j
  # end

  # it "should ignore emails from emission address" do
  #   Role.anonymous.update_attribute :permissions, [:add_work_packages]
  #   lambda do
  #     submit_email('ticket_from_emission_address.eml', {:work_package => {'project' => 'onlinestore'}, :unknown_user => 'create'}).should be_false
  #   end.should_not change(User, :count)
  # end

  # it "should send email notification if work_package added" do
  #   Setting.notified_events = ['work_package_added']
  #   ActionMailer::Base.deliveries.clear
  #   lambda do
  #     work_package = submit_email('ticket_on_given_project.eml')
  #     work_package_created(work_package)
  #   end.should change(ActionMailer::Base.deliveries, :size)
  # end

  # it "should add a work_package note" do
  #   journal = submit_email('ticket_reply.eml')
  #   journal.is_a?(Journal).should be_true
  #   journal.user.should == user
  #   journal.notes.should match(/This is reply/)
  #   journal.issue.type.name.should == type_support.name
  # end

  # it "should update work_package (Journal) with reply by message_id" do
  #   pending
  #   journal = submit_email('ticket_reply_by_message_id.eml')
  #   journal.is_a?(WorkPackageJournal).should be_true
  #   journal.user.should == user
  #   journal.journaled.should == existing_work_package
  #   journal.notes.should match(/This is reply/)
  #   journal.issue.type.name.should == type_feature.name
  # end

  # it "should change work_package attributes by adding an note" do
  #   journal = submit_email('ticket_reply_with_status.eml')
  #   journal.is_a?(Journal).should be_true
  #   work_package = work_package.find(journal.journaled.id)
  #   journal.user.should == user
  #   journal.journaled.should == existing_work_package
  #   journal.notes.should match(/This is reply/)
  #   journal.issue.type.name.should == type_support.name
  #   work_package.status.should == status_resolved
  #   work_package.start_date.to_s.should == '2010-01-01'
  #   work_package.due_date.to_s.should == '2010-12-31'
  #   work_package.assigned_to.should == user
  #   #issue.custom_value_for(CustomField.find_by_name('Float field')).value.should == "52.6"
  #   # keywords should be removed from the email body
  #   journal.notes.should_not match(/^Status:/i)
  #   journal.notes.should_not match(/^Start Date:/i)
  # end

  # it "should send email notification by adding an work_package note" do
  #   ActionMailer::Base.deliveries.clear
  #   lambda do
  #     journal = submit_email('ticket_reply.eml')
  #     journal.is_a?(Journal).should be_true
  #   end.should change(ActionMailer::Base.deliveries, :size)
  # end

  # it "should not set default attributes on adding a work_package note" do
  #   journal = submit_email('ticket_reply.eml', :work_package => {:type => 'Feature', :priority => 'High'})
  #   journal.is_a?(Journal).should be_true
  #   journal.notes.should match(/This is reply/)
  #   journal.issue.type.name.should == type_support.name
  #   journal.issue.priority.name.should == priority_low.name
  # end

  # it "should support message reply" do
  #   mes = submit_email('message_reply.eml')
  #   mes.is_a?(Message).should be_true
  #   mes.new_record?.should be_false
  #   mes.reload
  #   mes.subject.should == 'Reply via email'
  #   mes.parent.should == message_1
  # end

  # it "should support message reply by subject" do
  #   mes = submit_email('message_reply_by_subject.eml')
  #   mes.is_a?(Message).should be_true
  #   mes.new_record?.should be_false
  #   mes.reload
  #   mes.subject.should == 'Reply to the first post'
  #   mes.parent.should == message_1
  # end

  # it "should strip tags of html only emails" do
  #   work_package = submit_email('ticket_html_only.eml', :work_package => {'project' => 'onlinestore'})
  #   work_package_created(work_package)
  #   work_package.description.should == 'This is a html-only email.'
  # end

  # context "truncate emails based on the Setting" do
  #   context "with no setting" do
  #     before do
  #       Setting.mail_handler_body_delimiters = ''
  #     end

  #      it "should add the entire email into the work_package" do
  #       work_package = submit_email('ticket_on_given_project.eml')
  #       work_package_created(work_package)
  #       work_package.description.should include('---')
  #       work_package.description.should include('This paragraph is after the delimiter')
  #     end
  #   end

  #   context "with a single string" do
  #     before do
  #       Setting.mail_handler_body_delimiters = '---'
  #     end

  #     it "should truncate the email at the delimiter for the work_package" do
  #       work_package = submit_email('ticket_on_given_project.eml')
  #       work_package_created(work_package)
  #       work_package.description.should include('This paragraph is before delimiters')
  #       work_package.description.should include('--- This line starts with a delimiter')
  #       work_package.description.should_not match(/^---$/)
  #       work_package.description.should_not include('This paragraph is after the delimiter')
  #     end
  #   end

  #   context "with a single quoted reply (e.g. reply to a Redmine email notification)" do
  #     before do
  #       Setting.mail_handler_body_delimiters = '--- Reply above. Do not remove this line. ---'
  #     end

  #     it "should truncate the email at the delimiter with the quoted reply symbols (>)" do
  #       journal = submit_email('issue_update_with_quoted_reply_above.eml')
  #       journal.is_a?(Journal).should be_true
  #       journal.notes.should include('An update to the work_package by the sender.')
  #       journal.notes.should_not match(Regexp.escape("--- Reply above. Do not remove this line. ---"))
  #       journal.notes.should_not include('Looks like the JSON api for projects was missed.')
  #     end
  #   end

  #   context "with multiple quoted replies (e.g. reply to a reply of a Redmine email notification)" do
  #     before do
  #       Setting.mail_handler_body_delimiters = '--- Reply above. Do not remove this line. ---'
  #     end

  #     it "should truncate the email at the delimiter with the quoted reply symbols (>)" do
  #       journal = submit_email('issue_update_with_multiple_quoted_reply_above.eml')
  #       journal.is_a?(Journal).should be_true
  #       journal.notes.should include('An update to the work_package by the sender.')
  #       journal.notes.should_not match(Regexp.escape("--- Reply above. Do not remove this line. ---"))
  #       journal.notes.should_not include('Looks like the JSON api for projects was missed.')
  #     end
  #   end

  #   context "with multiple strings" do
  #     before do
  #       Setting.mail_handler_body_delimiters = "---\nBREAK"
  #     end

  #     it "truncate the email at the first delimiter found (BREAK)" do
  #       work_package = submit_email('ticket_on_given_project.eml')
  #       work_package_created(work_package)
  #       work_package.description.should include('This paragraph is before delimiters')
  #       work_package.description.should_not include('BREAK')
  #       work_package.description.should_not include('This paragraph is between delimiters')
  #       work_package.description.should_not match(/^---$/)
  #       work_package.description.should_not include('This paragraph is after the delimiter')
  #     end
  #   end
  # end

  # it "it shoud chomp subject on long email subject line" do
  #   work_package = submit_email('ticket_with_long_subject.eml')
  #   work_package_created(work_package)
  #   work_package.subject.should == 'New ticket on a given project with a very long subject line which exceeds 255 chars and should not be ignored but chopped off. And if the subject line is still not long enough, we just add more text. And more text. Wow, this is really annoying. Especially, if you have nothing to say...'[0,255]
  # end

  private

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
