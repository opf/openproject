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

describe Redmine::SafeAttributes do
  class Base
    def attributes=(attrs)
      attrs.each do |key, value|
        send("#{key}=", value)
      end
    end
  end

  class Person < Base
    attr_accessor :firstname, :lastname, :login
    include Redmine::SafeAttributes
    safe_attributes :firstname, :lastname
    safe_attributes :login, if: lambda { |_person, user| user.admin? }
  end

  class Book < Base
    attr_accessor :title, :isbn
    include Redmine::SafeAttributes
    safe_attributes :title
  end

  class PublishedBook < Book
    safe_attributes :isbn
  end

  before do
    @admin = User.find_by_login('admin') || FactoryGirl.create(:admin)
    @anonymous = User.anonymous || FactoryGirl.create(:anonymous)
  end

  it 'should safe attribute names' do
    p = Person.new
    assert_equal ['firstname', 'lastname'], p.safe_attribute_names(@anonymous)
    assert_equal ['firstname', 'lastname', 'login'], p.safe_attribute_names(@admin)
  end

  it 'should safe attribute names without user' do
    p = Person.new
    User.current = nil
    assert_equal ['firstname', 'lastname'], p.safe_attribute_names
    User.current = @admin
    assert_equal ['firstname', 'lastname', 'login'], p.safe_attribute_names
  end

  it 'should set safe attributes' do
    p = Person.new
    p.send('safe_attributes=', { 'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith' }, @anonymous)
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_nil p.login

    p = Person.new
    User.current = @admin
    p.send('safe_attributes=', { 'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith' }, @admin)
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_equal 'jsmith', p.login
  end

  it 'should set safe attributes without user' do
    p = Person.new
    User.current = nil
    p.safe_attributes = { 'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith' }
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_nil p.login

    p = Person.new
    User.current = @admin
    p.safe_attributes = { 'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith' }
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_equal 'jsmith', p.login
  end

  it 'should with indifferent access' do
    p = Person.new
    p.safe_attributes = { 'firstname' => 'Jack', lastname: 'Miller' }
    assert_equal 'Jack', p.firstname
    assert_equal 'Miller', p.lastname
  end

  it 'should use safe attributes in subclasses' do
    b = Book.new
    p = PublishedBook.new

    b.safe_attributes = { 'title' => 'My awesome Ruby Book', 'isbn' => '1221132343' }
    p.safe_attributes = { 'title' => 'The Pickaxe',          'isbn' => '1934356085' }

    assert_equal 'My awesome Ruby Book', b.title
    assert_nil b.isbn

    assert_equal 'The Pickaxe', p.title
    assert_equal '1934356085', p.isbn
  end
end
