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

RSpec.describe Wikis::TextFormatting::HtmlWikiLinkMatcher do
  subject(:html) { OpenProject::TextFormatting::Renderer.format_text(markdown) }

  describe ".applicable?" do
    it "is applicable to content containing a wiki link" do
      expect(described_class).to be_applicable("before [[[42:123]]] after")
    end

    it "is not applicable to content without a wiki link" do
      expect(described_class).not_to be_applicable("before [[Some wiki page]] after")
    end
  end

  context "with a wiki link as stored by the editor" do
    let(:markdown) { 'Read \[\[\[42:123\]\]\] first' }

    it "replaces the link with a deferred page link frame", :aggregate_failures do
      page = Capybara.string(html)

      expect(page).to have_css("turbo-frame[data-type='wiki-page-link']" \
                               "[data-provider-id='42']" \
                               "[data-page-identifier='123']")
      expect(page).to have_text("Read")
      expect(page).to have_text("first")
      expect(html).not_to include("[[[")
    end
  end

  context "with several wiki links" do
    let(:markdown) { '\[\[\[1:First\]\]\] and \[\[\[2:Second\]\]\]' }

    it "replaces each of them" do
      page = Capybara.string(html)

      expect(page).to have_css("turbo-frame[data-provider-id='1'][data-page-identifier='First']")
      expect(page).to have_css("turbo-frame[data-provider-id='2'][data-page-identifier='Second']")
    end
  end

  context "with a wiki link inside a code block" do
    let(:markdown) { "```\n[[[42:123]]]\n```" }

    it "keeps the link text unchanged" do
      expect(html).to include("[[[42:123]]]")
      expect(html).not_to include("turbo-frame")
    end
  end

  context "with a malformed wiki link" do
    let(:markdown) { '\[\[\[abc:123\]\]\]' }

    it "keeps the text unchanged" do
      expect(html).to include("[[[abc:123]]]")
      expect(html).not_to include("turbo-frame")
    end
  end
end
