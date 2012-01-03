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

class WatchersHelperTest < HelperTestCase
  include WatchersHelper

  # tested for backwards compatibility
  context '#watcher_tag' do
    setup do
      # mocking watcher_link to make sure, that new API is properly called from
      # the old one.
      def self.watcher_link(*args)
        @watcher_link_args = args
        nil
      end

      # silencing deprecation warnings while testing the deprecated behavior
      def self.watcher_tag(*args)
        ActiveSupport::Deprecation.silence { super }
      end
    end

    context 'without options' do
      should "call watcher_link with object, user and {:id => 'watcher', :replace => '#watcher'}" do
        watcher_tag(:object, :user)
        assert_equal :object, @watcher_link_args.first
        assert_equal :user, @watcher_link_args.second
        assert_equal({:id => 'watcher', :replace => ['#watcher']}, @watcher_link_args.third)
      end
    end

    context 'with replace, without id option' do
      should "set id to replace value and prefix replace with a # to make it a valid css selectors" do
        watcher_tag(:object, :user, :replace => 'abc')
        assert_equal :object, @watcher_link_args.first
        assert_equal :user, @watcher_link_args.second
        assert_equal({:id => 'abc', :replace => ['#abc']}, @watcher_link_args.third)
      end
    end

    context 'with all options' do
      should "prefix all elements in replace with a # to make them valid css selectors" do
        watcher_tag(:object, :user, :id => 'abc', :replace => ['abc', 'def'])
        assert_equal :object, @watcher_link_args.first
        assert_equal :user, @watcher_link_args.second
        assert_equal({:id => 'abc', :replace => ['#abc', '#def']}, @watcher_link_args.third)
      end
    end
  end
end
