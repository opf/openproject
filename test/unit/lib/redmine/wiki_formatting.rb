#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../../test_helper', __FILE__)

class Redmine::WikiFormattingTest < ActiveSupport::TestCase

  def test_textile_formatter
    assert_equal Redmine::WikiFormatting::Textile::Formatter, Redmine::WikiFormatting.formatter_for('textile')
    assert_equal Redmine::WikiFormatting::Textile::Helper, Redmine::WikiFormatting.helper_for('textile')
  end

  def test_null_formatter
    assert_equal Redmine::WikiFormatting::NullFormatter::Formatter, Redmine::WikiFormatting.formatter_for('')
    assert_equal Redmine::WikiFormatting::NullFormatter::Helper, Redmine::WikiFormatting.helper_for('')
  end

  def test_should_link_urls_and_email_addresses
    raw = <<-DIFF
This is a sample *text* with a link: http://www.redmine.org
and an email address foo@example.net
DIFF

    expected = <<-EXPECTED
<p>This is a sample *text* with a link: <a href="http://www.redmine.org">http://www.redmine.org</a><br />
and an email address <a href="mailto:foo@example.net">foo@example.net</a></p>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''), Redmine::WikiFormatting::NullFormatter::Formatter.new(raw).to_html.gsub(%r{[\r\n\t]}, '')
  end
end
