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

  def setup
    @admin = User.find_by_login("admin") || FactoryGirl.create(:admin)
    @anonymous = User.anonymous || FactoryGirl.create(:anonymous)
  end

  def test_safe_attribute_names
    p = Person.new
    assert_equal ['firstname', 'lastname'], p.safe_attribute_names(@anonymous)
    assert_equal ['firstname', 'lastname', 'login'], p.safe_attribute_names(@admin)
  end

  def test_safe_attribute_names_without_user
    p = Person.new
    User.current = nil
    assert_equal ['firstname', 'lastname'], p.safe_attribute_names
    User.current = @admin
    assert_equal ['firstname', 'lastname', 'login'], p.safe_attribute_names
  end

  def test_set_safe_attributes
    p = Person.new
    p.send('safe_attributes=', {'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith'}, @anonymous)
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_nil p.login

    p = Person.new
    User.current = @admin
    p.send('safe_attributes=', {'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith'}, @admin)
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
    User.current = @admin
    p.safe_attributes = {'firstname' => 'John', 'lastname' => 'Smith', 'login' => 'jsmith'}
    assert_equal 'John', p.firstname
    assert_equal 'Smith', p.lastname
    assert_equal 'jsmith', p.login
  end

  def test_with_indifferent_access
    p = Person.new
    p.safe_attributes = {'firstname' => 'Jack', :lastname => 'Miller'}
    assert_equal 'Jack', p.firstname
    assert_equal 'Miller', p.lastname
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
