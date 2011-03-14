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

require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::SafeAttributesTest < ActiveSupport::TestCase
  
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
    safe_attributes :login, :if => lambda {|person, user| user.admin?}
  end
  
  class Book < Base
    attr_accessor :title, :isbn
    include Redmine::SafeAttributes
    safe_attributes :title
  end
  

  class PublishedBook < Book
    safe_attributes :isbn
  end

  def test_safe_attribute_names
    p = Person.new
    assert_equal ['firstname', 'lastname'], p.safe_attribute_names(User.anonymous)
    assert_equal ['firstname', 'lastname', 'login'], p.safe_attribute_names(User.find(1))
  end
  
  def test_safe_attribute_names_without_user
    p = Person.new
    User.current = nil
    assert_equal ['firstname', 'lastname'], p.safe_attribute_names
    User.current = User.find(1)
    assert_equal ['firstname', 'lastname', 'login'], p.safe_attribute_names
  end
  
  def test_set_safe_attributes
    p = Person.new
    p.send('safe_attributes=', {'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith'}, User.anonymous)
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_nil p.login

    p = Person.new
    User.current = User.find(1)
    p.send('safe_attributes=', {'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith'}, User.find(1))
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_equal 'jsmith', p.login
  end
  
  def test_set_safe_attributes_without_user
    p = Person.new
    User.current = nil
    p.safe_attributes = {'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith'}
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_nil p.login

    p = Person.new
    User.current = User.find(1)
    p.safe_attributes = {'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith'}
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_equal 'jsmith', p.login
  end

  def test_use_safe_attributes_in_subclasses
    b = Book.new
    p = PublishedBook.new

    b.safe_attributes = {'title' => 'My awesome Ruby Book', 'isbn' => '1221132343'}
    p.safe_attributes = {'title' => 'The Pickaxe',          'isbn' => '1934356085'}

    assert_equal 'My awesome Ruby Book', b.title
    assert_nil b.isbn

    assert_equal 'The Pickaxe', p.title
    assert_equal '1934356085', p.isbn
  end
end
