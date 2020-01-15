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

describe 'search/index', type: :helper do
  let(:project) { FactoryBot.create(:project) }
  let(:scope) { 'foobar' }

  before do
    allow(helper).to receive(:params).and_return(
      q: 'foobar',
      all_words: '1',
      scope: scope
    )
    assign(:project, project)
  end

  describe '#highlight_tokens' do
    let(:maximum_length) { 1300 }

    subject { helper.highlight_tokens title, tokens }
    subject(:highlighted_title) { helper.highlight_tokens title, tokens }

    context 'with single token' do
      let(:tokens) { %w(token) }
      let(:title) { 'This is a token.' }
      let(:expected_title) { 'This is a <span class="search-highlight token-0">token</span>.' }

      it { is_expected.to eq expected_title }
    end

    context 'with multiple tokens' do
      let(:tokens) { %w(token another) }
      let(:title) { 'This is a token and another token.' }
      let(:expected_title) { 'This is a <span class="search-highlight token-0">token</span> and <span class="search-highlight token-1">another</span> <span class="search-highlight token-0">token</span>.' }

      it { is_expected.to eq expected_title }
    end

    context 'with huge content' do
      let(:tokens) { %w(token) }
      let(:title) { (('1234567890' * 100) + ' token ') * 100 }
      let(:highlighted_token) { '<span class="search-highlight token-0">token</span>' }

      it { expect(highlighted_title).to include highlighted_token }

      it 'does not exceed maximum length' do
        expect(highlighted_title.length).to be <= maximum_length
      end
    end

    context 'with multibyte title' do
      let(:tokens) { %w(token) }
      let(:title) { ('й' * 200) + ' token ' + ('й' * 200) }
      let(:expected_title) { ('й' * 45) + ' ... ' + ('й' * 44) + ' <span class="search-highlight token-0">token</span> ' + ('й' * 44) + ' ... ' + ('й' * 45) }

      it { is_expected.to eq expected_title }
    end
  end

  describe '#highlight_first' do
    let(:tokens) { %w(token) }

    subject { helper.highlight_first titles, tokens }

    context 'when first is matched' do
      let(:first) { 'This is a token' }
      let(:second) { 'I have some token for you' }
      let(:titles) { [first, second] }
      let(:first_highlighted) { 'This is a <span class="search-highlight token-0">token</span>' }

      it { is_expected.to eq first_highlighted }
    end

    context 'when first is not matched' do
      let(:first) { 'This is a book' }
      let(:second) { 'I have some token for you' }
      let(:titles) { [first, second] }
      let(:second_highlighted) { 'I have some <span class="search-highlight token-0">token</span> for you' }

      it { is_expected.to eq second_highlighted }
    end

    context 'when both first and second is not matched' do
      let(:first) { 'This is a book' }
      let(:second) { 'I have some book for you' }
      let(:titles) { [first, second] }

      it { is_expected.to eq second }
    end
  end
end
