#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe "Journalized Objects" do
  before(:each) do
    @type ||= FactoryGirl.create(:type_feature)
    @project ||= FactoryGirl.create(:project_with_types)
    @current = FactoryGirl.create(:user, :login => "user1", :mail => "user1@users.com")
    User.stub!(:current).and_return(@current)
  end


  it 'should work with issues' do
    @status_open ||= FactoryGirl.create(:issue_status, :name => "Open", :is_default => true)
    @issue ||= FactoryGirl.create(:issue, :project => @project, :status => @status_open, :type => @type, :author => @current)

    initial_journal = @issue.journals.first
    recreated_journal = @issue.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end

  it 'should work with news' do
    @news ||= FactoryGirl.create(:news, :project => @project, :author => @current, :title => "Test", :summary => "Test", :description => "Test")

    initial_journal = @news.journals.first
    recreated_journal = @news.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end


  it 'should work with wiki content' do
    @wiki_content ||= FactoryGirl.create(:wiki_content, :author => @current)

    initial_journal = @wiki_content.journals.first
    recreated_journal = @wiki_content.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end

  it 'should work with messages' do
    @message ||= FactoryGirl.create(:message, :content => "Test", :subject => "Test", :author => @current)

    initial_journal = @message.journals.first
    recreated_journal = @message.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end

  it 'should work with time entries' do
    @status_open ||= FactoryGirl.create(:issue_status, :name => "Open", :is_default => true)
    @issue ||= FactoryGirl.create(:issue, :project => @project, :status => @status_open, :type => @type, :author => @current)

    @time_entry ||= FactoryGirl.create(:time_entry, :work_package => @issue, :project => @project, :spent_on => Time.now, :hours => 5, :user => @current, :activity => FactoryGirl.create(:time_entry_activity))

    initial_journal = @time_entry.journals.first
    recreated_journal = @time_entry.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end

  it 'should work with attachments' do
    @attachment ||= FactoryGirl.create(:attachment, :container => FactoryGirl.create(:issue), :author => @current)

    initial_journal = @attachment.journals.first
    recreated_journal = @attachment.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end

  it 'should work with changesets' do
    Setting.enabled_scm = ["Subversion"]
    @repository ||= Repository.factory("Subversion", :url => "http://svn.test.com")
    @repository.save!
    @changeset ||= FactoryGirl.create(:changeset, :committer => @current.login, :repository => @repository)

    initial_journal = @changeset.journals.first
    recreated_journal = @changeset.recreate_initial_journal!

    initial_journal.should be_identical(recreated_journal)
  end
end
