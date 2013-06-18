#-- encoding: UTF-8
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
require_relative '../test_helper'

class DocumentTest < ActiveSupport::TestCase
  include MiniTest::Assertions # refute

  fixtures :all

  def setup
    super
    @documentation_category = FactoryGirl.create :document_category, :name => 'User documentation'
    @project = FactoryGirl.create :project
  end

  def test_create
    doc = Document.new(:project => @project, :title => 'New document', :category => @documentation_category)
    assert doc.save
  end

  def test_create_should_send_email_notification
    user = FactoryGirl.create(:user)
    doc = Document.new(:project => @project, :title => 'New document', :category => @documentation_category)
    # need to stub directly, otherwise it doesn't work. chili swallows all stubs... see next test
    doc.stubs(:recipients).returns([user.mail])

    Notifier.stubs(:notify?).with(:document_added).returns(true)
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert doc.save
    end
  end

  def test_recipients_equal_project_recipients
    # user must be allowed to :view_documents
    user = FactoryGirl.create(:user, :admin => true)
    @project.stubs(:notified_users).returns([user])
    document = FactoryGirl.create(:document, :project => @project)
    refute_empty document.recipients
    assert_equal document.recipients, @project.recipients
  end

  def test_create_with_default_category
    # Sets a default category
    e = FactoryGirl.create :document_category, :name => 'Technical documentation', :is_default => true
    doc = Document.new(:project => @project, :title => 'New document')
    assert_equal e, doc.category
    assert doc.save
  end

  def test_updated_on_with_attachments
    doc = FactoryGirl.create(:document, :project => @project)
    3.times do
      FactoryGirl.create :attachment, :container => doc
    end
    doc.reload
    assert doc.attachments.any?
    assert doc.attachments.size == 3
    assert_equal doc.attachments.map(&:created_on).max, doc.updated_on
  end

  def test_updated_on_without_attachments
    doc = FactoryGirl.create(:document, :project => @project)
    assert doc.attachments.empty?
    assert_equal doc.created_on, doc.updated_on
  end
end
