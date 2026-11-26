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

RSpec.describe OpenProject::TextFormatting::Filters::ExternalLinkCaptureFilter do
  let(:context) { {} }

  describe "#call" do
    context "when capture_external_links is disabled" do
      before do
        allow(Setting).to receive(:capture_external_links?).and_return(false)
      end

      it "does not modify external links" do
        html = '<a href="https://example.com">External</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="https://example.com"')
      end
    end

    context "when capture_external_links is enabled",
            with_ee: %i[capture_external_links],
            with_settings: {
              capture_external_links: true,
              host_name: "localhost:3000",
              https: false
            } do
      it "redirects external HTTP links" do
        html = '<a href="https://example.com">External</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="http://localhost:3000/external_redirect?url=')
        expect(output).to include(CGI.escape("https://example.com"))
      end

      it "redirects external HTTPS links" do
        html = '<a href="https://example.org">External</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="http://localhost:3000/external_redirect?url=')
        expect(output).to include(CGI.escape("https://example.org"))
      end

      it "redirects to the decoded URL of an escaped link" do
        html = '<a href="https://example.com/?a=1&amp;b=&quot;2&quot;&lt;">External</a>'
        output = described_class.call(html, context:)

        expect(output).to include(CGI.escape('https://example.com/?a=1&b="2"<'))
      end

      it "does not redirect relative links" do
        html = '<a href="/work_packages">Internal</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="/work_packages"')
      end

      it "does not redirect anchor links" do
        html = '<a href="#section">Anchor</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="#section"')
      end

      it "does not redirect mailto links" do
        html = '<a href="mailto:test@example.com">Email</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="mailto:test@example.com"')
      end

      it "does not redirect tel links" do
        html = '<a href="tel:+1234567890">Phone</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="tel:+1234567890"')
      end

      it "does not redirect ical links" do
        html = '<a href="webcal://example.com/calendar.ics">Calendar</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="webcal://example.com/calendar.ics"')
      end

      it "does not redirect custom protocol links" do
        html = '<a href="vscode://file/path/to/file">VS Code</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="vscode://file/path/to/file"')
      end

      it "does not redirect file protocol links" do
        html = '<a href="file:///path/to/file">File</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="file:///path/to/file"')
      end

      it "does not redirect internal links" do
        html = '<a href="http://localhost:3000/work_packages">Internal</a>'
        output = described_class.call(html, context:)

        expect(output).to include('href="http://localhost:3000/work_packages"')
      end

      context "with additional host names", with_settings: { additional_host_names: ["example.local"] } do
        it "does not redirect links from additional host names" do
          html = '<a href="http://example.local/work_packages">Internal</a>'
          output = described_class.call(html, context:)

          expect(output).to include('href="http://example.local/work_packages"')
        end
      end

      it "handles multiple links in the same document" do
        html = <<~HTML
          <p>Visit <a href="https://example.com">Example</a> or <a href="https://test.org">Test</a></p>
        HTML
        output = described_class.call(html, context:)

        expect(output).to include(CGI.escape("https://example.com"))
        expect(output).to include(CGI.escape("https://test.org"))
      end

      it "redirects external links in document output" do
        document = Nokogiri::HTML4::DocumentFragment.parse('<a href="https://example.com">External</a>')
        link = described_class.new(context:).decorate_document(document).at_css("a")

        expect(link["href"]).to start_with("http://localhost:3000/external_redirect?url=")
        expect(link["target"]).to eq("_blank")
      end
    end
  end
end
