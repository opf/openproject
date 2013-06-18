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

require File.expand_path('../../../../../../test_helper', __FILE__)

class Redmine::Views::Builders::JsonTest < HelperTestCase

  def test_hash
    assert_json_output({'person' => {'name' => 'Ryan', 'age' => 32}}) do |b|
      b.person do
        b.name 'Ryan'
        b.age  32
      end
    end
  end

  def test_hash_hash
    assert_json_output({'person' => {'name' => 'Ryan', 'birth' => {'city' => 'London', 'country' => 'UK'}}}) do |b|
      b.person do
        b.name 'Ryan'
        b.birth :city => 'London', :country => 'UK'
      end
    end

    assert_json_output({'person' => {'id' => 1, 'name' => 'Ryan', 'birth' => {'city' => 'London', 'country' => 'UK'}}}) do |b|
      b.person :id => 1 do
        b.name 'Ryan'
        b.birth :city => 'London', :country => 'UK'
      end
    end
  end

  def test_array
    assert_json_output({'books' => [{'title' => 'Book 1', 'author' => 'B. Smith'}, {'title' => 'Book 2', 'author' => 'G. Cooper'}]}) do |b|
      b.array :books do |b|
        b.book :title => 'Book 1', :author => 'B. Smith'
        b.book :title => 'Book 2', :author => 'G. Cooper'
      end
    end

    assert_json_output({'books' => [{'title' => 'Book 1', 'author' => 'B. Smith'}, {'title' => 'Book 2', 'author' => 'G. Cooper'}]}) do |b|
      b.array :books do |b|
        b.book :title => 'Book 1' do
          b.author 'B. Smith'
        end
        b.book :title => 'Book 2' do
          b.author 'G. Cooper'
        end
      end
    end
  end

  def test_array_with_content_tags
    assert_json_output({'books' => [{'value' => 'Book 1', 'author' => 'B. Smith'}, {'value' => 'Book 2', 'author' => 'G. Cooper'}]}) do |b|
      b.array :books do |b|
        b.book 'Book 1', :author => 'B. Smith'
        b.book 'Book 2', :author => 'G. Cooper'
      end
    end
  end

  def assert_json_output(expected, &block)
    builder = Redmine::Views::Builders::Json.new(ActionDispatch::TestRequest.new, ActionDispatch::TestResponse.new)
    block.call(builder)
    assert_equal(expected, ActiveSupport::JSON.decode(builder.output))
  end
end
