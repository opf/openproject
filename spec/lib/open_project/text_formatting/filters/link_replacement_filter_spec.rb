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

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe OpenProject::TextFormatting::Filters::LinkReplacementFilter do
  let(:filter) { described_class.new(html, context) }
  let(:context) { {} }
  let(:html) do
    '<a href="https://example.com">https://example.com</a> and ' \
      '<a href="https://example.com/foo">https://example.com/foo</a> are great websites.'
  end
  let(:handlers) { [double(new: handler), double(new: second_handler)] }
  let(:handler) do
    double("URL handler", match?: true).tap do |h|
      allow(h).to receive(:html_for) { |uri| %{<a class="fancy" href="#{uri}">a fancy link</a>} }
    end
  end
  let(:second_handler) { double("URL handler", match?: false) }

  before do
    allow(described_class).to receive(:handlers).and_return(handlers)
  end

  describe "#call" do
    subject(:result) { filter.call }

    it "replaces links according to handler" do
      expect(result.to_html).to eq(
        '<a class="fancy" href="https://example.com">a fancy link</a> and ' \
        '<a class="fancy" href="https://example.com/foo">a fancy link</a> are great websites.'
      )
    end

    it "calls the handler with all links found in the document" do
      subject

      expect(handler).to have_received(:match?).twice
      expect(handler).to have_received(:match?).with(URI.parse("https://example.com"))
      expect(handler).to have_received(:match?).with(URI.parse("https://example.com/foo"))

      expect(handler).to have_received(:html_for).twice
      expect(handler).to have_received(:html_for).with(URI.parse("https://example.com"))
      expect(handler).to have_received(:html_for).with(URI.parse("https://example.com/foo"))
    end

    it "does not look for other handlers" do
      subject

      expect(second_handler).not_to have_received(:match?)
    end

    context "when handler does not match a link" do
      before do
        allow(handler).to receive(:match?).and_return(false)
      end

      it "does not replace the link" do
        expect(result.to_html).to eq(html)
      end

      it "looks for other handlers" do
        subject

        expect(second_handler).to have_received(:match?).twice
      end
    end

    context "when a link has a custom text" do
      let(:html) do
        'The documentation can be found <a href="https://example.com">here</a>.'
      end

      it "does not replace the link" do
        expect(result.to_html).to eq(html)
      end

      it "does not call the handler about it" do
        subject

        expect(handler).not_to have_received(:match?)
        expect(handler).not_to have_received(:html_for)
      end
    end

    context "when multiple handlers match a link" do
      before do
        allow(second_handler).to receive_messages(match?: true, html_for: "link stolen")
      end

      it "replaces using the first handler" do
        expect(result.to_html).to eq(
          '<a class="fancy" href="https://example.com">a fancy link</a> and ' \
          '<a class="fancy" href="https://example.com/foo">a fancy link</a> are great websites.'
        )
      end

      it "does not look for other handlers" do
        subject

        expect(second_handler).not_to have_received(:match?)
      end
    end

    context "when a matching handler returns no replacement" do
      before do
        allow(handler).to receive(:html_for).and_return(nil)
      end

      it "does not replace the link" do
        expect(result.to_html).to eq(html)
      end

      it "does not look for other handlers" do
        subject

        expect(second_handler).not_to have_received(:match?)
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
