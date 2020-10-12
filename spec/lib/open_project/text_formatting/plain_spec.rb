#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

describe OpenProject::TextFormatting::Formats::Plain::Formatter do
  subject { described_class.new({}) }

  it 'should plain text' do
    assert_html_output('This is some input' => 'This is some input')
  end

  it 'should escaping' do
    assert_html_output(
      'this is a <script>' => 'this is a &lt;script&gt;'
    )
  end

  private

  def assert_html_output(to_test, expect_paragraph = true)
    to_test.each do |text, expected|
      assert_equal((expect_paragraph ? "<p>#{expected}</p>" : expected), subject.to_html(text), "Formatting the following text failed:\n===\n#{text}\n===\n")
    end
  end

  def to_html(text)
    subject.to_html(text)
  end
end
