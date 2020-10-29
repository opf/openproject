# frozen_string_literal: true

require 'test_helper'

class TestCommands < Minitest::Test
  def test_basic
    out = make_bin('strong.md')
    assert_equal out, '<p>I am <strong>strong</strong></p>'
  end

  def test_does_not_have_extensions
    out = make_bin('table.md')
    assert out.include?('| a')
    refute out.include?('<p><del>hi</del>')
    refute out.include?('<table> <tr> <th> a </th> <td> c </td>')
  end

  def test_understands_extensions
    out = make_bin('table.md', '--extension=table')
    refute out.include?('| a')
    refute out.include?('<p><del>hi</del>')
    %w[<table> <tr> <th> a </th> <td> c </td>].each { |html| assert out.include?(html) }
  end

  def test_understands_multiple_extensions
    out = make_bin('table.md', '--extension=table,strikethrough')
    refute out.include?('| a')
    assert out.include?('<p><del>hi</del>')
    %w[<table> <tr> <th> a </th> <td> c </td>].each { |html| assert out.include?(html) }
  end
end
