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

require File.expand_path('../../../../../../test_helper', __FILE__)

class Redmine::Views::Builders::XmlTest < HelperTestCase

  def test_hash
    assert_xml_output('<person><name>Ryan</name><age>32</age></person>') do |b|
      b.person do
        b.name 'Ryan'
        b.age  32
      end
    end
  end

  def test_array
    assert_xml_output('<books type="array"><book title="Book 1"/><book title="Book 2"/></books>') do |b|
      b.array :books do |b|
        b.book :title => 'Book 1'
        b.book :title => 'Book 2'
      end
    end
  end

  def test_array_with_content_tags
    assert_xml_output('<books type="array"><book author="B. Smith">Book 1</book><book author="G. Cooper">Book 2</book></books>') do |b|
      b.array :books do |b|
        b.book 'Book 1', :author => 'B. Smith'
        b.book 'Book 2', :author => 'G. Cooper'
      end
    end
  end

  def assert_xml_output(expected, &block)
    builder = Redmine::Views::Builders::Xml.new
    block.call(builder)
    assert_equal('<?xml version="1.0" encoding="UTF-8"?>' + expected, builder.output)
  end
end
