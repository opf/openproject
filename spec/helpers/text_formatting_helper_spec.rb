#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe TextFormattingHelper, type: :helper do
  describe '#preview_context' do
    context 'for a News' do
      let(:news) { FactoryBot.build_stubbed(:news) }

      it 'returns the v3 path' do
        expect(helper.preview_context(news))
          .to eql "/api/v3/news/#{news.id}"
      end
    end

    context 'for a Message' do
      let(:message) { FactoryBot.build_stubbed(:message) }

      it 'returns the v3 path' do
        expect(helper.preview_context(message))
          .to eql "/api/v3/posts/#{message.id}"
      end
    end

    context 'for a WikiPage' do
      let(:wiki_page) { FactoryBot.build_stubbed(:wiki_page) }

      it 'returns the v3 path' do
        expect(helper.preview_context(wiki_page))
          .to eql "/api/v3/wiki_pages/#{wiki_page.id}"
      end
    end
  end
end
