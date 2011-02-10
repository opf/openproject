# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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

require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::ConfigurationTest < ActiveSupport::TestCase
  def setup
    @conf = Redmine::Configuration
  end

  def test_empty
    assert_kind_of Hash, load_conf('empty.yml', 'test')
  end
  
  def test_default
    assert_kind_of Hash, load_conf('default.yml', 'test')
    assert_equal 'foo', @conf['somesetting']
  end
  
  def test_no_default
    assert_kind_of Hash, load_conf('no_default.yml', 'test')
    assert_equal 'foo', @conf['somesetting']
  end
  
  def test_overrides
    assert_kind_of Hash, load_conf('overrides.yml', 'test')
    assert_equal 'bar', @conf['somesetting']
  end
  
  private
  
  def load_conf(file, env)
    @conf.load(
      :file => File.join(Rails.root, 'test', 'fixtures', 'configuration', file),
      :env => env
    )
  end
end
