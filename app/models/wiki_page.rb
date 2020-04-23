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

class WikiPage < ApplicationRecord
  belongs_to :wiki, touch: true
  has_one :project, through: :wiki
  has_one :content, class_name: 'WikiContent', foreign_key: 'page_id', dependent: :destroy
  acts_as_attachable delete_permission: :delete_wiki_pages_attachments
  acts_as_tree dependent: :nullify, order: 'title'

  # Generate slug of the title
  acts_as_url :title,
              url_attribute: :slug,
              scope: :wiki_id, # Unique slugs per WIKI
              sync_url: true # Keep slug updated on #rename

  acts_as_watchable
  acts_as_event title: Proc.new { |o| "#{Wiki.model_name.human}: #{o.title}" },
                description: :text,
                datetime: :created_on,
                url: Proc.new { |o| { controller: '/wiki', action: 'show', project_id: o.wiki.project, id: o.title } }

  acts_as_searchable columns: ["#{WikiPage.table_name}.title", "#{WikiContent.table_name}.text"],
                     include: [{ wiki: :project }, :content],
                     references: [:wikis, :wiki_contents],
                     project_key: "#{Wiki.table_name}.project_id"

  attr_accessor :redirect_existing_links

  validates_presence_of :title
  validates_associated :content

  validate :validate_consistency_of_parent_title
  validate :validate_non_circular_dependency
  validate :validate_same_project

  before_save :update_redirects
  before_destroy :remove_redirects

  # eager load information about last updates, without loading text
  scope :with_updated_on, -> {
    select("#{WikiPage.table_name}.*, #{WikiContent.table_name}.updated_on")
      .joins("LEFT JOIN #{WikiContent.table_name} ON #{WikiContent.table_name}.page_id = #{WikiPage.table_name}.id")
  }

  scope :main_pages, ->(wiki_id) {
    where(wiki_id: wiki_id, parent_id: nil)
  }

  scope :visible, ->(user = User.current) {
    includes(:project)
      .references(:project)
      .merge(Project.allowed_to(user, :view_wiki_pages))
  }

  after_destroy :delete_wiki_menu_item

  def slug
    read_attribute(:slug).presence || title.try(:to_url)
  end

  def delete_wiki_menu_item
    menu_item.destroy if menu_item
    # ensure there is a menu item for the wiki
    wiki.create_menu_item_for_start_page if MenuItems::WikiMenuItem.main_items(wiki).empty?
  end

  def visible?(user = User.current)
    !user.nil? && user.allowed_to?(:view_wiki_pages, project)
  end

  def title=(value)
    @previous_title = read_attribute(:title) if @previous_title.blank?
    write_attribute(:title, value)
  end

  def update_redirects
    # Manage redirects if the title has changed
    if !@previous_title.blank? && (@previous_title != title) && !new_record?
      # Update redirects that point to the old title
      previous_slug = @previous_title.to_url
      wiki.redirects.where(redirects_to: previous_slug).each do |r|
        r.redirects_to = title
        r.title == r.redirects_to ? r.destroy : r.save
      end
      # Remove redirects for the new title
      wiki.redirects.where(title: slug).each(&:destroy)
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
    wiki.redirects.where(redirects_to: slug).each(&:destroy)
  end

  def content_for_version(version = nil)
    journal = content.versions.find_by(version: version.to_i) if version

    unless journal.nil? || content.version == journal.version
      content_version = WikiContent.new journal.data.attributes.except('id', 'journal_id')
      content_version.updated_on = journal.created_at
      content_version.journals = content.journals.select { |j| j.version <= version.to_i }

      content_version
    else
      content
    end
  end

  def diff(version_to = nil, version_from = nil)
    version_to = version_to ? version_to.to_i : content.version
    version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to

    content_to = content.versions.find_by(version: version_to)
    content_from = content.versions.find_by(version: version_from)

    (content_to && content_from) ? Wikis::Diff.new(content_to, content_from) : nil
  end

  def annotate(version = nil)
    version = version ? version.to_i : content.version
    c = content.versions.find_by(version: version)
    c ? Wikis::Annotate.new(c) : nil
  end

  def text
    content.text if content
  end

  def updated_on
    unless @updated_on
      if time = read_attribute(:updated_on)
        # content updated_on was eager loaded with the page
        unless time.is_a? Time
          time = Time.zone.parse(time) rescue nil
        end
        @updated_on = time
      else
        @updated_on = content && content.updated_on
      end
    end
    @updated_on
  end

  # Returns true if usr is allowed to edit the page, otherwise false
  def editable_by?(usr)
    !protected? || usr.allowed_to?(:protect_wiki_pages, wiki.project)
  end

  def attachments_deletable?(usr = User.current)
    editable_by?(usr) && super(usr)
  end

  def parent_title
    @parent_title || (parent && parent.title)
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
    if item = menu_item
      item.title
    else
      title
    end
  end

  def to_param
    slug || title.to_url
  end

  def save_with_content
    if valid? && content.valid?
      ActiveRecord::Base.transaction do
        save!
        content.save!
      end
      true
    end
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
