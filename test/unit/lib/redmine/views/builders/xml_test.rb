# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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
