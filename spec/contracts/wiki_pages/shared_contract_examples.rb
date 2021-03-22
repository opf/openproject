#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

shared_examples_for 'wiki page contract' do
  let(:current_user) do
    FactoryBot.build_stubbed(:user) do |user|
      allow(user)
        .to receive(:allowed_to?) do |permission, permission_project|
        permissions.include?(permission) && page_wiki.project == permission_project
      end
    end
  end
  let(:page_wiki) { FactoryBot.build_stubbed(:wiki) }
  let(:page_author) { current_user }
  let(:page_title) { 'Wiki title' }
  let(:page_slug) { 'wiki slug' }
  let(:page_protected) { false }
  let(:page_parent) { nil }
  let(:page_text) { 'Wiki text' }
  let(:permissions) { %i[view_wiki edit_wiki_pages] }

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  describe 'validation' do
    shared_examples 'is valid' do
      it 'is valid' do
        expect_valid(true)
      end
    end

    it_behaves_like 'is valid'

    context 'if the title is nil' do
      let(:page_title) { nil }

      it 'is invalid' do
        expect_valid(false, title: :blank)
      end
    end

    context 'if the slug is nil' do
      let(:page_slug) { nil }

      it_behaves_like 'is valid'
    end

    context 'if the wiki is nil' do
      let(:page_wiki) { nil }

      it 'is invalid' do
        expect_valid(false, wiki: :blank)
      end
    end

    context 'if the content is nil' do
      it 'is invalid' do
        page.content = nil

        expect_valid(false, content: :blank)
      end
    end

    context 'if the parent is in the same wiki' do
      let(:page_parent) { FactoryBot.build_stubbed(:wiki_page, wiki: page_wiki) }

      it_behaves_like 'is valid'
    end

    context 'if the parent is in a different wiki' do
      let(:page_parent) { FactoryBot.build_stubbed(:wiki_page) }

      it 'is invalid' do
        expect_valid(false, parent_title: :not_same_project)
      end
    end

    context 'if the parent is a child of the page (circular dependency)' do
      it 'is invalid' do
        page.parent = FactoryBot.build_stubbed(:wiki_page, wiki: page_wiki).tap do |parent|
          # Using stubbing here to avoid infinite loops
          allow(parent)
            .to receive(:ancestors)
            .and_return([page])
        end

        expect_valid(false, parent_title: :circular_dependency)
      end
    end

    context 'if the parent the page itself (circular dependency' do
      it 'is invalid' do
        page.parent = page

        expect_valid(false, parent_title: :circular_dependency)
      end
    end

    context 'if the author is nil' do
      let(:page_author) { nil }

      it 'is invalid' do
        expect_valid(false, author: %i[blank not_current_user])
      end
    end

    context 'if the user lacks permission' do
      let(:permissions) { %i[view_wiki] }

      it 'is invalid' do
        expect_valid(false, base: :error_unauthorized)
      end
    end

    context 'if the page is protected and the user has permission to protect pages' do
      let(:permissions) { %i[view_wiki edit_wiki_pages protect_wiki_pages] }
      let(:page_protected) { true }

      it_behaves_like 'is valid'
    end

    context 'if the page is protected and the user lacks permission to protect pages' do
      let(:page_protected) { true }

      it 'is invalid' do
        expect_valid(false, protected: :error_unauthorized)
      end
    end
  end
end
