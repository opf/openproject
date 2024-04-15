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

class WikiPage < ApplicationRecord
  belongs_to :wiki, touch: true
  has_one :project, through: :wiki
  belongs_to :author, class_name: 'User'

  acts_as_attachable delete_permission: :delete_wiki_pages_attachments
  acts_as_tree dependent: :nullify, order: 'title'

  # Generate slug of the title
  acts_as_url :title,
              url_attribute: :slug,
              scope: :wiki_id, # Unique slugs per WIKI
              sync_url: true, # Keep slug updated on #rename
              locale: :en,
              adapter: OpenProject::ActsAsUrl::Adapter::OpActiveRecord # use a custom adapter able to handle edge cases

  acts_as_watchable
  acts_as_event title: Proc.new { |o| "#{Wiki.model_name.human}: #{o.title}" },
                description: :text,
                url: Proc.new { |o| { controller: '/wiki', action: 'show', project_id: o.wiki.project, id: o.title } }

  acts_as_searchable columns: %W[#{WikiPage.table_name}.title text],
                     include: [{ wiki: :project }],
                     references: %i[wikis],
                     project_key: "#{Wiki.table_name}.project_id"

  acts_as_journalized

  register_journal_formatted_fields(:wiki_diff, 'text')

  attr_accessor :redirect_existing_links

  validates :title, presence: true
  validates :slug,
            presence: {
              message: ->(object, _) {
                I18n.t('activerecord.errors.models.wiki_page.attributes.slug.undeducible', title: object.title)
              }
            }

  validate :validate_consistency_of_parent_title
  validate :validate_non_circular_dependency
  validate :validate_same_project

  before_save :update_redirects
  before_destroy :remove_redirects

  scope :main_pages, ->(wiki_id) {
    where(wiki_id:, parent_id: nil)
  }

  scope :visible, ->(user = User.current) {
    includes(:project)
      .references(:project)
      .merge(Project.allowed_to(user, :view_wiki_pages))
  }

  after_destroy :delete_wiki_menu_item

  ##
  # Create a slug for the given title
  # We always want to generate english slugs
  # to avoid using the current user's locale
  def self.slug(title)
    title.to_localized_slug(locale: :en)
  end

  # Using a hook will not allow us to retry the call
  # rubocop:disable Rails/ActiveRecordOverride
  def destroy
    super
  rescue ActiveRecord::StaleObjectError
    # Due to closure_tree, parent_id might have changed
    # when destroying all wiki pages
    reload
    super
  end
  # rubocop:enable Rails/ActiveRecordOverride

  def delete_wiki_menu_item
    menu_item&.destroy
    # ensure there is a menu item for the wiki
    wiki.create_menu_item_for_start_page if MenuItems::WikiMenuItem.main_items(wiki).empty?
  end

  def visible?(user = User.current)
    !user.nil? && user.allowed_in_project?(:view_wiki_pages, project)
  end

  def title=(value)
    @previous_title = self[:title] if @previous_title.blank?
    write_attribute(:title, value)
  end

  def update_redirects
    # Manage redirects if the title has changed
    if @previous_title.present? && (@previous_title != title) && !new_record?
      # Update redirects that point to the old title
      previous_slug = WikiPage.slug(@previous_title)
      wiki.redirects.where(redirects_to: previous_slug).find_each do |r|
        r.redirects_to = title
        r.title == r.redirects_to ? r.destroy : r.save
      end
      # Remove redirects for the new title
      wiki.redirects.where(title: slug).find_each(&:destroy)
      # Create a redirect to the new title
      wiki.redirects << WikiRedirect.new(title: previous_slug, redirects_to: slug) unless redirect_existing_links == '0'

      # Change title of dependent wiki menu item
      dependent_item = MenuItems::WikiMenuItem.find_by(navigatable_id: wiki.id, name: previous_slug)
      if dependent_item
        dependent_item.name = slug
        dependent_item.title = title
        dependent_item.save!
      end

      @previous_title = nil
    end
  end

  # Remove redirects to this page
  def remove_redirects
    wiki.redirects.where(redirects_to: slug).find_each(&:destroy)
  end

  def diff(version_to = nil, version_from = nil)
    version_to = version_to ? version_to.to_i : version
    version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to

    content_to = journals.find_by(version: version_to)
    content_from = journals.find_by(version: version_from)

    content_to && content_from ? Wikis::Diff.new(content_to, content_from) : nil
  end

  def version
    last_journal.nil? ? 0 : last_journal.version
  end

  def annotate(compare_version = nil)
    compare_version = compare_version ? compare_version.to_i : version
    c = journals.find_by(version: compare_version)
    c ? Wikis::Annotate.new(c) : nil
  end

  # Returns true if usr is allowed to edit the page, otherwise false
  def editable_by?(usr)
    !protected? || usr.allowed_in_project?(:protect_wiki_pages, wiki.project)
  end

  def attachments_deletable?(usr = User.current)
    editable_by?(usr) && super(usr)
  end

  def parent_title
    @parent_title || parent&.title
  end

  def parent_title=(t)
    @parent_title = t
    parent_page = t.blank? ? nil : wiki.find_page(t)
    self.parent = parent_page
  end

  def menu_item
    MenuItems::WikiMenuItem.find_by(name: slug, navigatable_id: wiki_id)
  end

  # Returns the wiki menu item of nearest ancestor page that has a wiki menu item which is a main item.
  def nearest_main_item
    return nil unless parent

    if (parent_menu_item = parent.menu_item) && parent_menu_item.is_main_item?
      parent_menu_item
    else
      parent.nearest_main_item
    end
  end

  def breadcrumb_title
    menu_item&.title || title
  end

  def to_param
    slug || WikiPage.slug(title)
  end

  def only_wiki_page?
    wiki.pages == [self]
  end

  protected

  def validate_consistency_of_parent_title
    errors.add(:parent_title, :invalid) if @parent_title.present? && parent.nil?
  end

  def validate_non_circular_dependency
    errors.add(:parent_title, :circular_dependency) if parent && (parent == self || parent.ancestors.include?(self))
  end

  def validate_same_project
    errors.add(:parent_title, :not_same_project) if parent && (parent.wiki_id != wiki_id)
  end
end
