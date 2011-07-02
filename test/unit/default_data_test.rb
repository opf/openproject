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

class DefaultDataTest < ActiveSupport::TestCase
  include Redmine::I18n
  fixtures :roles

  def test_no_data
    assert !Redmine::DefaultData::Loader::no_data?
    Role.delete_all("builtin = 0")
    Tracker.delete_all
    IssueStatus.delete_all
    Enumeration.delete_all
    assert Redmine::DefaultData::Loader::no_data?
  end

  def test_load
    valid_languages.each do |lang|
      begin
        Role.delete_all("builtin = 0")
        Tracker.delete_all
        IssueStatus.delete_all
        Enumeration.delete_all
        assert Redmine::DefaultData::Loader::load(lang)
        assert_not_nil DocumentCategory.first
        assert_not_nil IssuePriority.first
        assert_not_nil TimeEntryActivity.first
      rescue ActiveRecord::RecordInvalid => e
        assert false, ":#{lang} default data is invalid (#{e.message})."
      end
    end
  end
end
