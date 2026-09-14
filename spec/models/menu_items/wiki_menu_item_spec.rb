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

RSpec.describe MenuItems::WikiMenuItem do
  let(:project) { create(:project, :with_internal_wiki, enabled_module_names: ["activity"]) }
  let(:user) { create(:user) }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  it "creates a default wiki menu item when an internal wiki is added" do
    expect(described_class.count).to eq(0)

    expect { project }.to change(described_class, :count).by(1)

    wiki_item = project.wiki.wiki_menu_items&.first
    expect(wiki_item.name).to eql "wiki"
    expect(wiki_item.title).to eql "Wiki"
    expect(wiki_item.slug).to eql "wiki"
    expect(wiki_item.options[:index_page]).to be true
    expect(wiki_item.options[:new_wiki_page]).to be true
  end

  it "changes title when a wiki_page is renamed" do
    wiki_page = create(:wiki_page, title: "Oldtitle")

    menu_item = create(:wiki_menu_item, navigatable_id: wiki_page.wiki.id, title: "Item 1", name: wiki_page.slug)

    wiki_page.update!(title: "Newtitle")

    expect(menu_item.reload.title).to eq(wiki_page.title)
  end

  it "does not allow duplicate sibling entries" do
    wiki_page = create(:wiki_page, title: "Parent Page")

    parent = create(
      :wiki_menu_item, navigatable_id: wiki_page.wiki.id, title: "Item 1", name: wiki_page.slug
    )
    parent.children.create name: "child-1", title: "Child 1"
    child_2 = parent.children.build name: "child-1", title: "Child 2"

    expect { child_2.save! }.to raise_error /Name has already been taken/
  end

  describe "it should destroy" do
    let!(:first_menu_item) { create(:wiki_menu_item, wiki: project.wiki) }
    let!(:second_menu_item) { create(:wiki_menu_item, wiki: project.wiki, parent: first_menu_item) }

    it "all children when deleting the parent" do
      first_menu_item.destroy

      expect { described_class.find(first_menu_item.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { described_class.find(second_menu_item.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "all items when destroying" do
      it "the associated project" do
        expect { project.destroy }.to change(described_class, :count).to(0)
      end

      it "the associated wiki" do
        expect { project.wiki.destroy }.to change(described_class, :count).to(0)
      end
    end
  end
end
