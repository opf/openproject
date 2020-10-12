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
require_relative '../legacy_spec_helper'

describe WikiContent, type: :model do
  fixtures :all

  before do
    @wiki = Wiki.find(1)
    @page = @wiki.pages.first
  end

  it 'should create' do
    page = WikiPage.new(wiki: @wiki, title: 'Page')
    page.content = WikiContent.new(text: 'Content text', author: User.find(1), comments: 'My comment')
    assert page.save
    page.reload

    content = page.content
    assert_kind_of WikiContent, content
    assert_equal 1, content.version
    assert_equal 1, content.versions.length
    assert_equal 'Content text', content.text
    assert_equal 'My comment', content.versions.last.notes
    assert_equal User.find(1), content.author
    assert_equal content.text, content.versions.last.data.text
  end

  it 'should update' do
    content = @page.content
    version_count = content.version
    content.text = 'My new content'
    assert content.save
    content.reload
    assert_equal version_count + 1, content.version
    assert_equal version_count + 1, content.versions.length
  end

  it 'should fetch history' do
    wiki_content_journal = FactoryBot.create(:wiki_content_journal,
                                             journable: @page.content)
    wiki_content_journal.data.update_attributes(page_id: @page.id, text: '')

    assert !@page.content.journals.empty?
    @page.content.journals.each do |journal|
      assert_kind_of String, journal.data.text
    end
  end

  it 'should large text should not be truncated to 64k' do
    page = WikiPage.new(wiki: @wiki, title: 'Big page')
    page.content = WikiContent.new(text: 'a' * 500.kilobyte, author: User.find(1))
    assert page.save
    page.reload
    assert_equal 500.kilobyte, page.content.text.size
  end

  specify 'new WikiContent is version 0' do
    page = WikiPage.new(wiki: @wiki, title: 'Page')
    page.content = WikiContent.new(text: 'Content text', author: User.find(1), comments: 'My comment')

    assert_equal 0, page.content.version
  end
end
