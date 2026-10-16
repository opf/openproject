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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe SanitizationHelper do
  describe "#sanitize_basic_html" do
    subject(:sanitized) { helper.sanitize_basic_html(html) }

    let(:html) do
      <<~HTML
        <ul>
          <li><a href="/work_packages/1">#1</a></li>
        </ul>
        <p>ignored</p>
      HTML
    end

    it "keeps lists and relative links and returns HTML-safe" do
      expect(sanitized).to include("<ul>")
      expect(sanitized).to include("<li>")
      expect(sanitized).to include('href="/work_packages/1"')
      expect(sanitized).not_to include("<p>")
      expect(sanitized).to be_html_safe
    end

    it "keeps phrasing tags used in job status HTML" do
      html = %(<br/> <b>3 files could not be read</b> and were excluded. <strong>incomplete</strong>)

      expect(helper.sanitize_basic_html(html)).to include("<br>")
      expect(helper.sanitize_basic_html(html)).to include("<b>")
      expect(helper.sanitize_basic_html(html)).to include("<strong>")
    end

    it "strips javascript: hrefs" do
      html = %(<a href="javascript:alert(1)">link</a>)

      expect(helper.sanitize_basic_html(html)).not_to match(/href="javascript:/i)
    end

    it "keeps only protocols allowed by Setting::AllowedLinkProtocols" do
      allow(Setting).to receive(:allowed_link_protocols).and_return(["sftp"])

      kept = helper.sanitize_basic_html(%(<a href="sftp://files.example/a">a</a>))
      stripped = helper.sanitize_basic_html(%(<a href="ftp://files.example/a">a</a>))

      expect(kept).to include('href="sftp://files.example/a"')
      expect(stripped).not_to include("ftp://")
    end
  end
end
