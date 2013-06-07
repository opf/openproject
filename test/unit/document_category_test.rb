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

class DocumentCategoryTest < ActiveSupport::TestCase
  def test_should_be_an_enumeration
    assert DocumentCategory.ancestors.include?(Enumeration)
  end

  def test_objects_count
    project = FactoryGirl.create :project
    uncategorized = FactoryGirl.create :document_category, :name => "Uncategorized", :project => project
    FactoryGirl.create :document_category, :name => "User documentation"
    FactoryGirl.create_list :document, 2, :category => uncategorized, :project => project

    assert_equal 2, DocumentCategory.find_by_name("Uncategorized").objects_count
    assert_equal 0, DocumentCategory.find_by_name("User documentation").objects_count
  end

  def test_option_name
    assert_equal :enumeration_doc_categories, DocumentCategory.new.option_name
  end
end

