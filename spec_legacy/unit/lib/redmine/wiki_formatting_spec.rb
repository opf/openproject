#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Redmine::WikiFormatting do
  it 'should textile formatter' do
    assert_equal Redmine::WikiFormatting::Textile::Formatter, Redmine::WikiFormatting.formatter_for('textile')
    assert_equal Redmine::WikiFormatting::Textile::Helper, Redmine::WikiFormatting.helper_for('textile')
  end

  it 'should null formatter' do
    assert_equal Redmine::WikiFormatting::NullFormatter::Formatter, Redmine::WikiFormatting.formatter_for('')
    assert_equal Redmine::WikiFormatting::NullFormatter::Helper, Redmine::WikiFormatting.helper_for('')
  end

  it 'should link urls and email addresses' do
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
