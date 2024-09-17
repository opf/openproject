#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "expected_markdown"

RSpec.describe OpenProject::TextFormatting::Formats::Markdown::Formatter do
  it "modifierses" do
    assert_html_output(
      "**bold**" => "<strong>bold</strong>",
      "before **bold**" => "before <strong>bold</strong>",
      "**bold** after" => "<strong>bold</strong> after",
      "**two words**" => "<strong>two words</strong>",
      "**two*words**" => "<strong>two*words</strong>",
      "**two * words**" => "<strong>two * words</strong>",
      "**two** **words**" => "<strong>two</strong> <strong>words</strong>",
      "**(two)** **(words)**" => "<strong>(two)</strong> <strong>(words)</strong>"
    )
  end

  it "escapes script tags" do
    assert_html_output(
      "this is a <script>" => "this is a &lt;script&gt;"
    )
  end

  it "doubles dashes should not strikethrough" do
    assert_html_output(
      "double -- dashes -- test" => "double -- dashes -- test",
      "double -- **dashes** -- test" => "double -- <strong>dashes</strong> -- test"
    )
  end

  it "does not mangle brackets" do
    expect(to_html("[msg1][msg2]")).to eq '<p class="op-uc-p">[msg1][msg2]</p>'
  end

  private

  def assert_html_output(to_test, options = {})
    options = { expect_paragraph: true }.merge options
    expect_paragraph = options.delete :expect_paragraph

    to_test.each do |text, expected|
      expected = "<p class=\"op-uc-p\">#{expected}</p>" if expect_paragraph
      expect(to_html(text, options)).to be_html_eql expected
    end
  end

  def to_html(text, options = {})
    described_class.new(options).to_html(text)
  end
end
