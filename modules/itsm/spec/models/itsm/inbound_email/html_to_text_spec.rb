# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe ITSM::InboundEmail::HtmlToText do
  subject(:text) { described_class.call(html) }

  let(:html) do
    "<html><head><style>p { color: red }</style></head><body>" \
      "<p>Hello <b>team</b>,</p><p>first line<br>second line</p>" \
      "<p>a &amp; b &lt;c&gt;</p><script>alert('hi')</script>" \
      "</body></html>"
  end

  it "keeps the text with its line breaks" do
    expect(text).to eq("Hello team,\n\nfirst line\nsecond line\n\na & b <c>")
  end

  context "with styling and active content" do
    let(:html) do
      "<html><head><link rel=\"stylesheet\" href=\"https://styles.example/mail.css\"></head><body>" \
        "<p style=\"color: red; background: url(https://tracker.example/pixel.gif)\" onclick=\"alert(1)\">Hello</p>" \
        "<img src=\"https://tracker.example/pixel.gif\" onerror=\"alert(1)\">" \
        "<iframe src=\"https://frame.example\">frame</iframe><object>object</object>" \
        "<!-- hidden comment --><svg><style>p { display: none }</style></svg>" \
        "</body></html>"
    end

    it "keeps only the visible text" do
      expect(text).to eq("Hello")
    end
  end

  context "with links" do
    let(:html) do
      "<p>See <a href=\"https://shop.example/orders/123\">my order</a>, " \
        "<a href=\"https://shop.example\">https://shop.example</a>, " \
        "<a href=\"mailto:jane@customer.example\">Jane</a>, " \
        "<a href=\"mailto:joe@customer.example\">joe@customer.example</a>, " \
        "<a href=\"#top\">top</a> and " \
        "<a href=\"javascript:alert(1)\">this</a>.</p>"
    end

    it "keeps web and email addresses, but not anchors or unsafe targets" do
      expect(text).to eq("See my order (https://shop.example/orders/123), https://shop.example, " \
                         "Jane (jane@customer.example), joe@customer.example, top and this.")
    end
  end
end
