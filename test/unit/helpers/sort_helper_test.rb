#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)

class SortHelperTest < HelperTestCase
  include SortHelper

  def setup
    @session = nil
    @sort_param = nil
  end

  def test_default_sort_clause_with_array
    sort_init 'attr1', 'desc'
    sort_update(['attr1', 'attr2'])

    assert_equal 'attr1 DESC', sort_clause
  end

  def test_default_sort_clause_with_hash
    sort_init 'attr1', 'desc'
    sort_update({'attr1' => 'table1.attr1', 'attr2' => 'table2.attr2'})

    assert_equal 'table1.attr1 DESC', sort_clause
  end

  def test_default_sort_clause_with_multiple_columns
    sort_init 'attr1', 'desc'
    sort_update({'attr1' => ['table1.attr1', 'table1.attr2'], 'attr2' => 'table2.attr2'})

    assert_equal 'table1.attr1 DESC, table1.attr2 DESC', sort_clause
  end

  def test_params_sort
    @sort_param = 'attr1,attr2:desc'

    sort_init 'attr1', 'desc'
    sort_update({'attr1' => 'table1.attr1', 'attr2' => 'table2.attr2'})

    assert_equal 'table1.attr1, table2.attr2 DESC', sort_clause
    assert_equal 'attr1,attr2:desc', @session['foo_bar_sort']
  end

  def test_invalid_params_sort
    @sort_param = 'invalid_key'

    sort_init 'attr1', 'desc'
    sort_update({'attr1' => 'table1.attr1', 'attr2' => 'table2.attr2'})

    assert_equal 'table1.attr1 DESC', sort_clause
    assert_equal 'attr1:desc', @session['foo_bar_sort']
  end

  def test_invalid_order_params_sort
    @sort_param = 'attr1:foo:bar,attr2'

    sort_init 'attr1', 'desc'
    sort_update({'attr1' => 'table1.attr1', 'attr2' => 'table2.attr2'})

    assert_equal 'table1.attr1, table2.attr2', sort_clause
    assert_equal 'attr1,attr2', @session['foo_bar_sort']
  end

  private

  def controller_name; 'foo'; end
  def action_name; 'bar'; end
  def params; {:sort => @sort_param}; end
  def session; @session ||= {}; end
end
