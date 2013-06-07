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

#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class VersionedTest < Test::Unit::TestCase
  context 'ActiveRecord models' do
    should 'respond to the "journaled?" method' do
      assert ActiveRecord::Base.respond_to?(:journaled?)
      assert User.respond_to?(:journaled?)
    end

    should 'return true for the "journaled?" method if the model is journaled' do
      assert_equal true, User.journaled?
    end

    should 'return false for the "journaled?" method if the model is not journaled' do
      assert_equal false, ActiveRecord::Base.journaled?
    end
  end
end
