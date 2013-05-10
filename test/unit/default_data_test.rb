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
require File.expand_path('../../test_helper', __FILE__)

class DefaultDataTest < ActiveSupport::TestCase
  include Redmine::I18n

  def setup
    super
    delete_loaded_data!
    assert Redmine::DefaultData::Loader::no_data?
  end

  def test_no_data
    Redmine::DefaultData::Loader::load
    assert !Redmine::DefaultData::Loader::no_data?

    delete_loaded_data!
    assert Redmine::DefaultData::Loader::no_data?
  end

  def test_load
    valid_languages.each do |lang|
      begin
        delete_loaded_data!
        assert Redmine::DefaultData::Loader::load(lang)
        klasses.each do |klass|
          assert klass.any?
        end
      rescue ActiveRecord::RecordInvalid => e
        assert false, ":#{lang} default data is invalid (#{e.message})."
      end
    end
  end

private

  def delete_loaded_data!
    klasses.each(&:delete_all)
  end

  def klasses
    [
      User, Role, Tracker, IssueStatus,
      Enumeration, Workflow, DocumentCategory,
      IssuePriority, TimeEntryActivity
    ]
  end
end
