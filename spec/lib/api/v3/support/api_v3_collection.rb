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

shared_examples_for 'generic APIv3 collection' do
  describe '_links' do
    it 'has a self link' do
      expect(collection).to be_json_eql(self_link.to_json).at_path('_links/self/href')
    end
  end

  it 'has a collection type' do
    expected_type = defined?(collection_type) ? collection_type : 'Collection'
    expect(collection).to be_json_eql(expected_type.to_json).at_path('_type')
  end

  describe 'elements are typed correctly' do
    it do
      expect(collection).to be_json_eql(collection_inner_type.to_json)
                              .at_path('_embedded/elements/0/_type')
    end
  end
end

shared_examples_for 'unpaginated APIv3 collection' do |count, self_link, type|
  it_behaves_like 'generic APIv3 collection' do
    let(:self_link) { "/api/v3/#{self_link}" }
    let(:collection_inner_type) { type }
  end

  describe 'quantities' do
    it { expect(collection).to be_json_eql(count.to_json).at_path('total') }

    it { expect(collection).to be_json_eql(count.to_json).at_path('count') }

    it { expect(collection).to have_json_size(count).at_path('_embedded/elements') }
  end
end

shared_examples_for 'offset-paginated APIv3 collection' do
  def make_link_for(page:, page_size:)
    page = ::ERB::Util::url_encode(page)
    page_size = ::ERB::Util::url_encode(page_size)
    "#{self_base_link}?offset=#{page}&pageSize=#{page_size}"
  end

  it_behaves_like 'generic APIv3 collection' do
    let(:self_link) { make_link_for(page: page, page_size: page_size) }
  end

  describe '_links' do
    it_behaves_like 'has a templated link' do
      let(:link) { 'jumpTo' }
      let(:href) { make_link_for(page: '{offset}', page_size: page_size) }
    end

    it_behaves_like 'has a templated link' do
      let(:link) { 'changeSize' }
      let(:href) { make_link_for(page: page, page_size: '{size}') }
    end
  end

  it 'indicates the page number as offset' do
    expect(collection).to be_json_eql(page.to_json).at_path('offset')
  end

  it 'indicates the expected pageSize' do
    expect(collection).to be_json_eql(page_size.to_json).at_path('pageSize')
  end

  it 'indicates the total amount of elements (over all pages)' do
    expect(collection).to be_json_eql(total.to_json).at_path('total')
  end

  it 'indicates the number of elements on this page' do
    expect(collection).to be_json_eql(actual_count.to_json).at_path('count')
  end

  it 'embeds the expected number of elements' do
    expect(collection).to have_json_size(actual_count).at_path('_embedded/elements')
  end

  shared_examples_for 'links to previous page by offset' do
    it_behaves_like 'has an untitled link' do
      let(:link) { 'previousByOffset' }
      let(:href) { make_link_for(page: page - 1, page_size: page_size) }
    end
  end

  shared_examples_for 'links to next page by offset' do
    it_behaves_like 'has an untitled link' do
      let(:link) { 'nextByOffset' }
      let(:href) { make_link_for(page: page + 1, page_size: page_size) }
    end
  end
end
