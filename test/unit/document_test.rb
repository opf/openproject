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
require File.expand_path('../../test_helper', __FILE__)

class DocumentTest < ActiveSupport::TestCase
  fixtures :all

  def test_create
    doc = Document.new(:project => Project.find(1), :title => 'New document', :category => Enumeration.find_by_name('User documentation'))
    assert doc.save
  end

  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Setting.notified_events.dup << 'document_added'
    doc = Document.new(:project => Project.find(1), :title => 'New document', :category => Enumeration.find_by_name('User documentation'))

    assert doc.save
    assert_equal 2, ActionMailer::Base.deliveries.size
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

  should "allow watchers" do
    assert Document.included_modules.include?(Redmine::Acts::Watchable::InstanceMethods)
    assert Document.new.respond_to?(:add_watcher)
  end

  context "#recipients" do
    should "include watchers" do
      document = Document.generate!(:project => Project.find(1))
      user = User.find(1)
      assert document.add_watcher(user)

      assert document.save

      assert document.recipients.include?(user.mail), "Watcher not included in recipients"
    end
  end
  
end
