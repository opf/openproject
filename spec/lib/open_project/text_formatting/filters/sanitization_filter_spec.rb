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
# along with this program; if not, write to the GNU General Public
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::TextFormatting::Filters::SanitizationFilter do
  let(:context) { {} }

  def sanitize(html)
    filter = described_class.new(html, context)
    result = filter.call
    result.respond_to?(:to_html) ? result.to_html : result.to_s
  end

  describe "DOM clobbering prevention via fragment id prefix" do
    # id/name are prefixed with op-frag- so they cannot clobber document/window.
    # Anchors still work because fragment links are rewritten to use the same prefix.
    let(:prefix) { described_class::FRAGMENT_ID_PREFIX }

    context "when HTML contains id and name attributes" do
      it "prefixes name attribute so it cannot clobber" do
        html = '<p><img src="x" name="constructor" alt="" /></p>'
        output = sanitize(html)
        expect(output).not_to include('name="constructor"')
        expect(output).to include("name=\"#{prefix}constructor\"")
      end

      it "prefixes name on multiple elements" do
        html = '<p><img src="x" name="adoptNode" /><img src="x" name="getElementById" /></p>'
        output = sanitize(html)
        expect(output).to include("name=\"#{prefix}adoptNode\"")
        expect(output).to include("name=\"#{prefix}getElementById\"")
      end

      it "prefixes id attribute so it cannot clobber" do
        html = '<p><span id="constructor">text</span></p>'
        output = sanitize(html)
        expect(output).not_to include('id="constructor"')
        expect(output).to include("id=\"#{prefix}constructor\"")
      end

      it "does not double-prefix id or name" do
        html = "<p><span id=\"#{prefix}already\">x</span></p>"
        output = sanitize(html)
        expect(output).to include("id=\"#{prefix}already\"")
        expect(output).not_to include("id=\"#{prefix}#{prefix}")
      end
    end

    context "when HTML contains same-document fragment links" do
      it "rewrites href to use prefix so anchors match" do
        html = '<p><a href="#section">Jump</a></p>'
        output = sanitize(html)
        expect(output).to include("href=\"##{prefix}section\"")
      end

      it "does not rewrite empty fragment or full URLs" do
        html = '<p><a href="#">Top</a> <a href="https://example.com#anchor">External</a></p>'
        output = sanitize(html)
        expect(output).to include('href="#"')
        expect(output).to include('href="https://example.com#anchor"')
      end
    end

    context "when markdown produces a link with injected img tags (real-world payload)" do
      it "prefixes name attributes so they cannot clobber" do
        html = <<~HTML
          <p><a href="https://xyz.com">foobar</a><img src="x" name="constructor" /><img src="x" name="appendChild" /></p>
        HTML
        output = sanitize(html)
        expect(output).not_to match(/name=["']constructor["']/)
        expect(output).to include("name=\"#{prefix}constructor\"")
        expect(output).to include("name=\"#{prefix}appendChild\"")
      end
    end
  end

  describe "CSS injection prevention" do
    context "when trying an overlay via position:fixed" do
      it "strips position and z-index from figure elements" do
        html = '<figure class="image" style="position:fixed;top:0;left:0;width:100%;height:100%;z-index:99999">content</figure>'
        output = sanitize(html)
        expect(output).not_to include("position")
        expect(output).not_to include("z-index")
        expect(output).not_to include("top:0")
        expect(output).not_to include("left:0")
      end

      it "strips position and z-index from table cells" do
        html = '<table><tr><td style="position:fixed;z-index:99998;width:100%;height:100%">content</td></tr></table>'
        output = sanitize(html)
        expect(output).not_to include("position")
        expect(output).not_to include("z-index")
      end
    end

    context "when trying CSS-based images with URL" do
      it "strips background-image with url() from table cells" do
        html = '<table><tr><td style="background-image:url(https://attacker.example.com/track);width:0;height:0">content</td></tr></table>'
        output = sanitize(html)
        expect(output).not_to include("background-image")
        expect(output).not_to include("attacker.example.com")
      end

      it "strips border-image with url() from table cells" do
        html = <<~HTML
          <table>
            <tr>
              <td style="border-image:url(https://attacker.example.com/exfil) 30;border-width:1px">
                content
              </td>
            </tr>
          </table>
        HTML

        output = sanitize(html)
        expect(output).not_to include("border-image")
        expect(output).not_to include("attacker.example.com")
      end
    end

    context "when safe formatting CSS is preserved" do
      it "preserves text-align on table cells" do
        html = '<table><tr><td style="text-align:center">content</td></tr></table>'
        output = sanitize(html)
        expect(output).to include("text-align")
      end

      it "preserves background-color on table cells" do
        html = '<table><tr><td style="background-color:#ff0000">content</td></tr></table>'
        output = sanitize(html)
        expect(output).to include("background-color")
      end

      it "preserves width and height on img elements" do
        html = '<p><img src="image.png" alt="" style="width:100px;height:50px" /></p>'
        output = sanitize(html)
        expect(output).to include("width")
        expect(output).to include("height")
      end

      it "preserves border styling on tables" do
        html = '<table style="border-collapse:collapse"><tr><td style="border:1px solid #ccc">content</td></tr></table>'
        output = sanitize(html)
        expect(output).to include("border-collapse")
        expect(output).to include("border")
      end

      it "preserves float on figure for image alignment" do
        html = '<figure class="image" style="float:left;margin:1em">content</figure>'
        output = sanitize(html)
        expect(output).to include("float")
        expect(output).to include("margin")
      end
    end
  end
end
