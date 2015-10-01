#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe SortHelper, type: :helper do
  include SortHelper

  before do
    @session = nil
    @sort_param = nil
  end

  it 'should default_sort_clause_with_array' do
    sort_init 'attr1', 'desc'
    sort_update(['attr1', 'attr2'])

    assert_equal 'attr1 DESC', sort_clause
  end

  it 'should default_sort_clause_with_hash' do
    sort_init 'attr1', 'desc'
    sort_update('attr1' => 'table1.attr1', 'attr2' => 'table2.attr2')

    assert_equal 'table1.attr1 DESC', sort_clause
  end

  it 'should default_sort_clause_with_multiple_columns' do
    sort_init 'attr1', 'desc'
    sort_update('attr1' => ['table1.attr1', 'table1.attr2'], 'attr2' => 'table2.attr2')

    assert_equal 'table1.attr1 DESC, table1.attr2 DESC', sort_clause
  end

  it 'should params_sort' do
    @sort_param = 'attr1,attr2:desc'

    sort_init 'attr1', 'desc'
    sort_update('attr1' => 'table1.attr1', 'attr2' => 'table2.attr2')

    assert_equal 'table1.attr1, table2.attr2 DESC', sort_clause
    assert_equal 'attr1,attr2:desc', @session['foo_bar_sort']
  end

  it 'should invalid_params_sort' do
    @sort_param = 'invalid_key'

    sort_init 'attr1', 'desc'
    sort_update('attr1' => 'table1.attr1', 'attr2' => 'table2.attr2')

    assert_equal 'table1.attr1 DESC', sort_clause
    assert_equal 'attr1:desc', @session['foo_bar_sort']
  end

  it 'should invalid_order_params_sort' do
    @sort_param = 'attr1:foo:bar,attr2'

    sort_init 'attr1', 'desc'
    sort_update('attr1' => 'table1.attr1', 'attr2' => 'table2.attr2')

    assert_equal 'table1.attr1, table2.attr2', sort_clause
    assert_equal 'attr1,attr2', @session['foo_bar_sort']
  end

  private

  def controller_name; 'foo'; end

  def action_name; 'bar'; end

  def params; { sort: @sort_param }; end

  def session; @session ||= {}; end
end
