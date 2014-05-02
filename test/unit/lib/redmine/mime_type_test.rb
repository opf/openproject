#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
require File.expand_path('../../../../test_helper', __FILE__)

describe Redmine::MimeType do

  it 'should of' do
    to_test = {'test.unk' => nil,
               'test.txt' => 'text/plain',
               'test.c' => 'text/x-c',
               }
    to_test.each do |name, expected|
      assert_equal expected, Redmine::MimeType.of(name)
    end
  end

  it 'should css_class_of' do
    to_test = {'test.unk' => nil,
               'test.txt' => 'text-plain',
               'test.c' => 'text-x-c',
               }
    to_test.each do |name, expected|
      assert_equal expected, Redmine::MimeType.css_class_of(name)
    end
  end

  it 'should main_mimetype_of' do
    to_test = {'test.unk' => nil,
               'test.txt' => 'text',
               'test.c' => 'text',
               }
    to_test.each do |name, expected|
      assert_equal expected, Redmine::MimeType.main_mimetype_of(name)
    end
  end

  it 'should is_type' do
    to_test = {['text', 'test.unk'] => false,
               ['text', 'test.txt'] => true,
               ['text', 'test.c'] => true,
               }
    to_test.each do |args, expected|
      assert_equal expected, Redmine::MimeType.is_type?(*args)
    end
  end

  def test_narrow_type_for_equal_main_type
    assert_equal 'text/x-ruby', Redmine::MimeType.narrow_type('rubyfile.rb', 'text/plain')
  end

  def test_use_original_type_if_main_type_differs
    assert_equal 'application/zip', Redmine::MimeType.narrow_type('rubyfile.rb', 'application/zip')
  end
end
