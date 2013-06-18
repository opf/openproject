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

require File.expand_path('../../../../../test_helper', __FILE__)

class Redmine::WikiFormatting::NullFormatterTest < HelperTestCase

  def setup
    @formatter = Redmine::WikiFormatting::NullFormatter::Formatter
  end

  def test_plain_text
    assert_html_output("This is some input" => "This is some input")
  end

  def test_escaping
    assert_html_output(
      'this is a <script>'      => 'this is a &lt;script&gt;'
    )
  end

private

  def assert_html_output(to_test, expect_paragraph = true)
    to_test.each do |text, expected|
      assert_equal(( expect_paragraph ? "<p>#{expected}</p>" : expected ), @formatter.new(text).to_html, "Formatting the following text failed:\n===\n#{text}\n===\n")
    end
  end

  def to_html(text)
    @formatter.new(text).to_html
  end
end
