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

RSpec.describe OpenProject::TextFormatting do
  include OpenProject::TextFormatting

  it "markdowns formatter" do
    expect(OpenProject::TextFormatting::Formats::Markdown::Formatter).to eq(OpenProject::TextFormatting::Formats.rich_formatter)
    expect(OpenProject::TextFormatting::Formats::Markdown::Helper).to eq(OpenProject::TextFormatting::Formats.rich_helper)
  end

  it "plains formatter" do
    expect(OpenProject::TextFormatting::Formats::Plain::Formatter).to eq(OpenProject::TextFormatting::Formats.plain_formatter)
    expect(OpenProject::TextFormatting::Formats::Plain::Helper).to eq(OpenProject::TextFormatting::Formats.plain_helper)
  end

  it "links urls and email addresses" do
    raw = <<~DIFF
      This is a sample *text* with a link: http://www.redmine.org
      and an email address foo@example.net
    DIFF

    expected = <<~EXPECTED
      <p>This is a sample *text* with a link: <a href="http://www.redmine.org">http://www.redmine.org</a><br>
      and an email address <a href="mailto:foo@example.net">foo@example.net</a></p>
    EXPECTED

    expect(expected.gsub(%r{[\r\n\t]},
                         "")).to eq(OpenProject::TextFormatting::Formats::Plain::Formatter.new({}).to_html(raw).gsub(
                                      %r{[\r\n\t]}, ""
                                    ))
  end

  describe "options" do
    describe "#format" do
      it "uses format of Settings, if nothing is specified" do
        expect(format_text("_Stars!_")).to be_html_eql('<p class="op-uc-p"><em>Stars!</em></p>')
      end

      it "allows plain format of options, if specified" do
        expect(format_text("*Stars!*", format: "plain")).to be_html_eql("<p>*Stars!*</p>")
      end
    end
  end
end
