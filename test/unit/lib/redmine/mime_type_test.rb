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
require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::MimeTypeTest < ActiveSupport::TestCase

  def test_of
    to_test = {'test.unk' => nil,
               'test.txt' => 'text/plain',
               'test.c' => 'text/x-c',
               }
    to_test.each do |name, expected|
      assert_equal expected, Redmine::MimeType.of(name)
    end
  end

  def test_css_class_of
    to_test = {'test.unk' => nil,
               'test.txt' => 'text-plain',
               'test.c' => 'text-x-c',
               }
    to_test.each do |name, expected|
      assert_equal expected, Redmine::MimeType.css_class_of(name)
    end
  end

  def test_main_mimetype_of
    to_test = {'test.unk' => nil,
               'test.txt' => 'text',
               'test.c' => 'text',
               }
    to_test.each do |name, expected|
      assert_equal expected, Redmine::MimeType.main_mimetype_of(name)
    end
  end

  def test_is_type
    to_test = {['text', 'test.unk'] => false,
               ['text', 'test.txt'] => true,
               ['text', 'test.c'] => true,
               }
    to_test.each do |args, expected|
      assert_equal expected, Redmine::MimeType.is_type?(*args)
    end
  end
end
