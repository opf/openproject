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

class MenuItems::WikiMenuItem < MenuItem
  belongs_to :wiki, foreign_key: "navigatable_id"

  scope :main_items, ->(wiki_id) {
    where(navigatable_id: wiki_id, parent_id: nil)
      .includes(:children)
      .order(Arel.sql("title ASC"))
  }

  def slug
    WikiPage.slug(name)
  end

  def item_class
    slug
  end

  def menu_identifier
    :"wiki-#{slug}"
  end

  def index_page
    !!options[:index_page]
  end

  def index_page=(value)
    options[:index_page] = value
  end

  def new_wiki_page
    !!options[:new_wiki_page]
  end

  def new_wiki_page=(value)
    options[:new_wiki_page] = value
  end

  def as_entry_item_symbol
    self.class.add_entry_item_prefix(menu_identifier)
  end

  def self.add_entry_item_prefix(identifier)
    :"entry-item-#{identifier}"
  end
end
