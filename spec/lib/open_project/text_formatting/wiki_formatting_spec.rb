#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'

describe OpenProject::WikiFormatting do
  it 'should markdown formatter' do
    expect(OpenProject::TextFormatting::Formatters::Markdown::Formatter).to eq(OpenProject::TextFormatting::Formatters.formatter_for('markdown'))
    expect(OpenProject::TextFormatting::Formatters::Markdown::Helper).to eq(OpenProject::TextFormatting::Formatters.helper_for('markdown'))
  end

  it 'should textile formatter' do
    expect(OpenProject::TextFormatting::Formatters::Textile::Formatter).to eq(OpenProject::TextFormatting::Formatters.formatter_for('textile'))
    expect(OpenProject::TextFormatting::Formatters::Textile::Helper).to eq(OpenProject::TextFormatting::Formatters.helper_for('textile'))
  end

  it 'should plain formatter' do
    expect(OpenProject::TextFormatting::Formatters::Plain::Formatter).to eq(OpenProject::TextFormatting::Formatters.formatter_for('plain'))
    expect(OpenProject::TextFormatting::Formatters::Plain::Helper).to eq(OpenProject::TextFormatting::Formatters.helper_for('plain'))

    expect(OpenProject::TextFormatting::Formatters::Plain::Formatter).to eq(OpenProject::TextFormatting::Formatters.formatter_for('doesnotexist'))
    expect(OpenProject::TextFormatting::Formatters::Plain::Helper).to eq(OpenProject::TextFormatting::Formatters.helper_for('doesnotexist'))
  end

  it 'should link urls and email addresses' do
    raw = <<-DIFF
This is a sample *text* with a link: http://www.redmine.org
and an email address foo@example.net
DIFF

    expected = <<-EXPECTED
<p>This is a sample *text* with a link: <a href="http://www.redmine.org">http://www.redmine.org</a><br>
and an email address <a href="mailto:foo@example.net">foo@example.net</a></p>
EXPECTED

    assert_equal expected.gsub(%r{[\r\n\t]}, ''),OpenProject::TextFormatting::Formatters::Plain::Formatter.new({}).to_html(raw).gsub(%r{[\r\n\t]}, '')
  end
end
