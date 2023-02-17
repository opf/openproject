#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe TextFormattingHelper do
  describe '#preview_context' do
    context 'for a News' do
      let(:news) { build_stubbed(:news) }

      it 'returns the v3 path' do
        expect(helper.preview_context(news))
          .to eql "/api/v3/news/#{news.id}"
      end
    end

    context 'for a Message' do
      let(:message) { build_stubbed(:message) }

      it 'returns the v3 path' do
        expect(helper.preview_context(message))
          .to eql "/api/v3/posts/#{message.id}"
      end
    end

    context 'for a WikiPage' do
      let(:wiki_page) { build_stubbed(:wiki_page) }

      it 'returns the v3 path' do
        expect(helper.preview_context(wiki_page))
          .to eql "/api/v3/wiki_pages/#{wiki_page.id}"
      end
    end
  end

  describe 'truncate_formatted_text' do
    it 'truncates given text' do
      text = <<~TEXT.squish
        Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam
        nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam
        erat, sed diam voluptua. At vero eos et accusam et justo duo dolores
        et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem
        ipsum dolor sit amet. Lore
      TEXT

      expect(truncate_formatted_text(text).size).to eq(123)
    end

    it 'replaces escaped line breaks with html line breaks and should be html_safe' do
      text = "Lorem ipsum dolor sit \namet, consetetur sadipscing elitr, sed diam nonumy eirmod\n tempor invidunt"
      text_html = 'Lorem ipsum dolor sit <br /> amet, consetetur sadipscing elitr, sed diam nonumy eirmod <br /> tempor invidunt'
      expect(truncate_formatted_text(text))
        .to be_html_eql(text_html)
      expect(truncate_formatted_text(text))
        .to be_html_safe
    end

    it 'escapes potentially harmful code' do
      text = "Lorem ipsum dolor <script>alert('pwnd');</script> tempor invidunt"
      expect(truncate_formatted_text(text))
        .to include('&lt;script&gt;alert(\'pwnd\');&lt;/script&gt;')
    end
  end
end
