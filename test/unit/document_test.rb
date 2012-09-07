#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require_relative '../test_helper'

class DocumentTest < ActiveSupport::TestCase
  fixtures :projects, :enumerations, :documents, :attachments

  def test_create
    doc = Document.new(:project => Project.find(1), :title => 'New document', :category => Enumeration.find_by_name('User documentation'))
    assert doc.save
  end

  def test_create_should_send_email_notification
    user = FactoryGirl.create(:user)
    project = FactoryGirl.create(:project)
    doc = Document.new(:project => project, :title => 'New document', :category => Enumeration.find_by_name('User documentation'))
    # need to stub directly, otherwise it doesn't work. chili swallows all stubs... see next test
    doc.stubs(:recipients).returns([user.mail])

    Notifier.stubs(:notify?).with(:document_added).returns(true)
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert doc.save
    end
  end

  # this should pass unless the stubbing doesn't work
  # since it fails, it doesn't :(
  def test_recipients_equal_project_recipients
    user = FactoryGirl.create(:user)
    project = FactoryGirl.create(:project)
    project.stubs(:notified_users).returns([user])
    document = FactoryGirl.create(:document, :project => project)
    refute_empty document.recipients
    assert_equal document.recipients, project.recipients
  end

  def test_create_with_default_category
    # Sets a default category
    e = Enumeration.find_by_name('Technical documentation')
    e.update_attributes(:is_default => true)

    doc = Document.new(:project => Project.find(1), :title => 'New document')
    assert_equal e, doc.category
    assert doc.save
  end

  def test_updated_on_with_attachments
    d = Document.find(1)
    assert d.attachments.any?
    assert_equal d.attachments.map(&:created_on).max, d.updated_on
  end

  def test_updated_on_without_attachments
    d = Document.find(2)
    assert d.attachments.empty?
    assert_equal d.created_on, d.updated_on
  end
end
