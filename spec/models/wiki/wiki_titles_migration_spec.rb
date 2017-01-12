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

require 'spec_helper'
require Rails.root.join('db/migrate/20160726090624_add_slug_to_wiki_pages.rb')

describe Wiki, type: :model do
  describe 'Wiki titles migration' do
    let(:project) { FactoryGirl.create :project }
    let(:wiki_page) {
      FactoryGirl.create :wiki_page_with_content,
                         wiki: project.wiki,
                         title: 'CookBook documentation'
    }

    let(:old_page_1) {
      FactoryGirl.create :wiki_page_with_content,
                         wiki: project.wiki,
                         title: 'CookBook_documentation'
    }
    let(:old_page_2) {
      FactoryGirl.create :wiki_page_with_content,
                         wiki: project.wiki,
                         title: 'base_de_donées'
    }

    let(:old_page_3) {
      FactoryGirl.create :wiki_page_with_content,
                         wiki: project.wiki,
                         title: 'asciionly'
    }

    subject { project.wiki }

    before do
      project.wiki.pages << old_page_1
      project.wiki.pages << old_page_2
      project.wiki.pages << old_page_3

      # Run the title replacement of the migration
      ::AddSlugToWikiPages.new.migrate_titles

      old_page_1.reload
      old_page_2.reload
      old_page_3.reload
    end

    it 'creates a redirect for the legacy page' do
      redirect = WikiRedirect.where(title: 'CookBook_documentation').first
      expect(redirect).not_to be_nil
      expect(redirect.redirects_to).to eq(old_page_1.slug)
    end

    it 'does not create a redirect unless necessary' do
      redirect = WikiRedirect.where(title: 'asciionly').first
      expect(redirect).to be_nil
    end

    it 'sets title and slug' do
      expect(old_page_1.title).to eq('CookBook documentation')
      expect(old_page_1.slug).to eq('cookbook-documentation')

      expect(old_page_2.title).to eq('base de donées')
      expect(old_page_2.slug).to eq('base-de-donees')

      expect(old_page_3.title).to eq('asciionly')
      expect(old_page_3.slug).to eq('asciionly')
    end

    it 'locates the legacy pages' do
      page = subject.find_page('CookBook documentation')
      expect(page).to eq(old_page_1)

      page = subject.find_page('CookBook documentation')
      expect(page).to eq(old_page_1)

      page = subject.find_page('base_de_donées')
      expect(page).to eq(old_page_2)

      page = subject.find_page('base de donées')
      expect(page).to eq(old_page_2)
    end

    context 'trying to create same page' do
      it 'will create a new slug' do
        expect { wiki_page }.not_to raise_error
        wiki_page.reload

        expect(wiki_page.slug).to eq('cookbook-documentation-1')
      end
    end
  end
end
