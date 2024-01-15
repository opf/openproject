#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

  validates :start_page, presence: true

  after_create :create_menu_item_for_start_page

  def visible?(user = User.current)
    !user.nil? && user.allowed_in_project?(:view_wiki_pages, project)
  end

  # find the page with the given title
  # if page doesn't exist, return a new page
  def find_or_new_page(title)
    title = start_page if title.blank?
    # If a new page is initialized, it needs to have a slug (via the ensure_unique_url)
    # method right away, so that the correct menu item (if that exists already) is highlighted
    find_page(title) || WikiPage.new(wiki: self, title:).tap(&:ensure_unique_url)
  end

  ##
  # Find the page with the given title.
  # Tries the original title and the legacy titleized format.
  def find_page(title, options = {})
    title = start_page if title.blank?

    page = find_matching_slug(title)

    if !page && !(options[:with_redirect] == false)
      # search for a redirect
      redirect = matching_redirect(title)
      page = find_page(redirect.redirects_to, with_redirect: false) if redirect
    end
    page
  end

  ##
  # Find a page by its slug
  # first trying the english slug, and then the slug for the default language
  # as that was previous behavior (cf., Bug OP#38606)
  def find_matching_slug(title)
    pages
      .where(slug: WikiPage.slug(title))
      .or(pages.where(slug: title.to_localized_slug(locale: Setting.default_language)))
      .first
  end

  # Finds a page by title
  # The given string can be of one of the forms: "title" or "project:title"
  # Examples:
  #   Wiki.find_page("bar", project => foo)
  #   Wiki.find_page("foo:bar")
  def self.find_page(title, options = {})
    project = options[:project]
    if title.to_s =~ %r{\A([^:]+):(.*)\z}
      project_identifier = $1
      title = $2
      project = Project.find_by(identifier: project_identifier) || Project.find_by(name: project_identifier)
    end
    if project && project.wiki
      project.wiki.find_page(title)
    end
  end

  def create_menu_item_for_start_page
    wiki_menu_item = wiki_menu_items.find_or_initialize_by(title: start_page) do |item|
      item.name = 'wiki'
    end
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
    redirects
      .where(title: WikiPage.slug(title))
      .or(redirects.where(title:))
      .first
  end
end
