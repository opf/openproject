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
require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::NotifiableTest < ActiveSupport::TestCase
  def setup
  end

  def test_all
    assert_equal 11, Redmine::Notifiable.all.length

    %w(issue_added issue_updated issue_note_added issue_status_updated issue_priority_updated news_added news_comment_added file_added message_posted wiki_content_added wiki_content_updated).each do |notifiable|
      assert Redmine::Notifiable.all.collect(&:name).include?(notifiable), "missing #{notifiable}"
    end
  end
end
