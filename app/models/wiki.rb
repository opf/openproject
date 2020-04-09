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

class Wiki < ApplicationRecord
  belongs_to :project
  has_many :pages, -> {
    order('title')
  }, class_name: 'WikiPage', dependent: :destroy
  has_many :wiki_menu_items, -> {
    order('name')
  }, class_name: 'MenuItems::WikiMenuItem', dependent: :delete_all, foreign_key: 'navigatable_id'
  has_many :redirects, class_name: 'WikiRedirect', dependent: :delete_all

  acts_as_watchable permission: :view_wiki_pages

  accepts_nested_attributes_for :wiki_menu_items,
                                allow_destroy: true,
                                reject_if: proc { |attr| attr['name'].blank? && attr['title'].blank? }

  validates_presence_of :start_page

  after_create :create_menu_item_for_start_page

  def visible?(user = User.current)
    !user.nil? && user.allowed_to?(:view_wiki_pages, project)
  end

  # find the page with the given title
  # if page doesn't exist, return a new page
  def find_or_new_page(title)
    title = start_page if title.blank?
    find_page(title) || WikiPage.new(wiki: self, title: title)
  end

  ##
  # Find the page with the given title.
  # Tries the original title and the legacy titleized format.
  def find_page(title, options = {})
    title = start_page if title.blank?

    page = pages.where(slug: title.to_url).first
    if !page && !(options[:with_redirect] == false)
      # search for a redirect
      redirect = matching_redirect(title)
      page = find_page(redirect.redirects_to, with_redirect: false) if redirect
    end
    page
  end

  # Finds a page by title
  # The given string can be of one of the forms: "title" or "project:title"
  # Examples:
  #   Wiki.find_page("bar", project => foo)
  #   Wiki.find_page("foo:bar")
  def self.find_page(title, options = {})
    project = options[:project]
    if title.to_s =~ %r{\A([^\:]+)\:(.*)\z}
      project_identifier = $1
      title = $2
      project = Project.find_by(identifier: project_identifier) || Project.find_by(name: project_identifier)
    end
    if project && project.wiki
      page = project.wiki.find_page(title)
      if page && page.content
        page
      end
    end
  end

  def create_menu_item_for_start_page
    wiki_menu_item = wiki_menu_items.find_or_initialize_by(title: start_page) { |item|
      item.name = 'wiki'
    }
    wiki_menu_item.new_wiki_page = true
    wiki_menu_item.index_page = true

    wiki_menu_item.save!
  end

  private

  ##
  # Locate the redirect from an existing page.
  # Tries to find a redirect for the given slug,
  # falls back to finding a redirect for the title
  def matching_redirect(title)
    page = redirects.where(title: title.to_url).first

    if page.nil?
      page = redirects.where(title: title).first
    end

    page
  end
end
