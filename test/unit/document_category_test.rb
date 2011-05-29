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

class DocumentCategoryTest < ActiveSupport::TestCase
  fixtures :enumerations, :documents, :issues

  def test_should_be_an_enumeration
    assert DocumentCategory.ancestors.include?(Enumeration)
  end
  
  def test_objects_count
    assert_equal 2, DocumentCategory.find_by_name("Uncategorized").objects_count
    assert_equal 0, DocumentCategory.find_by_name("User documentation").objects_count
  end

  def test_option_name
    assert_equal :enumeration_doc_categories, DocumentCategory.new.option_name
  end
end

