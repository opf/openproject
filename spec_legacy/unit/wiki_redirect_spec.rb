#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe WikiRedirect, type: :model do
  fixtures :all

  before do
    @wiki = Wiki.find(1)
    @original = WikiPage.create(wiki: @wiki, title: 'Original title')
  end

  it 'should create redirect' do
    @original.title = 'New title'
    assert @original.save
    @original.reload

    assert_equal 'New title', @original.title
    assert @wiki.redirects.find_by(title: 'original-title')
    assert @wiki.find_page('Original title')
    assert @wiki.find_page('ORIGINAL title')
  end

  it 'should update redirect' do
    # create a redirect that point to this page
    assert WikiRedirect.create(wiki: @wiki, title: 'An old page', redirects_to: @original.slug)

    @original.title = 'New title'
    @original.save
    # make sure the old page now points to the new page
    assert_equal 'New title', @wiki.find_page('An old page').title
  end

  it 'should reverse rename' do
    # create a redirect that point to this page
    assert WikiRedirect.create(wiki: @wiki, title: 'An old page', redirects_to: @original.slug)

    @original.title = 'An old page'
    @original.save
    assert !@wiki.redirects.find_by(title: 'an-old-page', redirects_to: 'an-old-page')
    assert @wiki.redirects.find_by(title: 'original-title', redirects_to: 'an-old-page')
  end

  it 'should rename to already redirected' do
    assert WikiRedirect.create(wiki: @wiki, title: 'an-old-page', redirects_to: 'other-page')

    @original.title = 'An old page'
    @original.save
    # this redirect have to be removed since 'An old page' page now exists
    assert !@wiki.redirects.find_by(title: 'an-old-page', redirects_to: 'other-page')
  end

  it 'should redirects removed when deleting page' do
    assert WikiRedirect.create(wiki: @wiki, title: 'an-old-page', redirects_to: @original.slug)

    @original.destroy
    assert !@wiki.redirects.first
  end
end
