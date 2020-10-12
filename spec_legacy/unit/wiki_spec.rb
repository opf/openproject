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
require 'legacy_spec_helper'

describe Wiki, type: :model do
  fixtures :all

  it 'should create' do
    wiki = Wiki.new(project: Project.find(2))
    assert !wiki.save
    assert_equal 1, wiki.errors.count

    wiki.start_page = 'Start page'
    assert wiki.save
  end

  it 'should update' do
    @wiki = Wiki.find(1)
    @wiki.start_page = 'Another start page'
    assert @wiki.save
    @wiki.reload
    assert_equal 'Another start page', @wiki.start_page
  end

  it 'should find page' do
    wiki = Wiki.find(1)
    page = WikiPage.find(2)

    assert_equal page, wiki.find_page('Another page')
    assert_equal page, wiki.find_page('ANOTHER page')

    page = WikiPage.find(10)
    assert_equal page, wiki.find_page('Этика менеджмента')

    page = FactoryBot.create(:wiki_page, wiki: wiki, title: '2009\\02\\09')
    assert_equal page, wiki.find_page('2009\\02\\09')
  end
end
