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

  def test_with
    load_conf('default.yml', 'test')
    assert_equal 'foo', @conf['somesetting']
    @conf.with 'somesetting' => 'bar' do
      assert_equal 'bar', @conf['somesetting']
    end
    assert_equal 'foo', @conf['somesetting']
  end

  private

  def load_conf(file, env)
    @conf.load(
      :file => File.join(Rails.root, 'test', 'fixtures', 'configuration', file),
      :env => env
    )
  end
end
