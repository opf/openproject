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

class CreateWikiMenuItemForExistingWikis < ActiveRecord::Migration[4.2]
  class OldWikiMenuItem < ActiveRecord::Base
    self.table_name = "wiki_menu_items"

    serialize :options, Hash

    belongs_to :wiki, :foreign_key => 'wiki_id'

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
  end

  class OldWiki < ActiveRecord::Base
    self.table_name = "wikis"

    belongs_to :project, :foreign_key => 'wiki_id'
    has_many :pages, :class_name => 'WikiPage', :foreign_key => 'wiki_id'
    has_many :wiki_menu_items, :class_name => 'MenuItems::WikiMenuItem', :foreign_key => 'wiki_id'
    has_many :redirects, :class_name => 'WikiRedirect', :foreign_key => 'wiki_id'

    # find the page with the given title
    def find_page(title, options = {})
      title = start_page if title.blank?
      title = titleize(title)
      page = find_first pages, title
      if !page && !(options[:with_redirect] == false)
        # search for a redirect
        redirect = find_first redirects, title
        page = find_page(redirect.redirects_to, :with_redirect => false) if redirect
      end
      page
    end

    def find_first(pages, title)
      pages.where("LOWER(title) = LOWER(?)", title).order(id: :asc).first
    end

    def titleize(title)
      # replace spaces with _ and remove unwanted caracters
      title = title.gsub(/\s+/, '_').delete(',./?;|:') if title
      # upcase the first letter
      title = (title.slice(0..0).upcase + (title.slice(1..-1) || '')) if title
      title
    end
  end

  def self.up
    OldWiki.all.each do |wiki|
      page = wiki.find_page(wiki.start_page, with_redirects: true)

      current_title = page.present? ?
                        page.title :
                        wiki.start_page

      menu_item = OldWikiMenuItem.new
      menu_item.name = wiki.start_page
      menu_item.title = current_title
      menu_item.wiki_id = wiki.id
      menu_item.index_page = true
      menu_item.new_wiki_page = true

      menu_item.save!
    end
  end

  def self.down
    puts 'You cannot safely undo this migration!'
  end
end
