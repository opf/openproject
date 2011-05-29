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
require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::NotifiableTest < ActiveSupport::TestCase
  def setup
  end

  def test_all
    assert_equal 12, Redmine::Notifiable.all.length

    %w(issue_added issue_updated issue_note_added issue_status_updated issue_priority_updated news_added news_comment_added document_added file_added message_posted wiki_content_added wiki_content_updated).each do |notifiable|
      assert Redmine::Notifiable.all.collect(&:name).include?(notifiable), "missing #{notifiable}"
    end
  end
end
