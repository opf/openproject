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

class PersistedView < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :principal, optional: true, inverse_of: :persisted_views
  belongs_to :query, polymorphic: true, optional: true, autosave: true

  belongs_to :parent, class_name: "PersistedView", optional: true
  has_many :children, class_name: "PersistedView", foreign_key: "parent_id", dependent: :destroy, inverse_of: :parent

  acts_as_favoritable

  enum :category, {
    work_package: "work_package",
    project: "project",
    resource_management: "resource_management"
  }, validate: { allow_nil: true }

  validates :name, presence: true, length: { maximum: 255 }
  validate :parent_allows_this_child_class

  scope :public_views, -> { where(public: true) }
  scope :private_views, ->(principal = User.current) { where(public: false, principal_id: principal.id) }
  scope :with_children, -> { includes(:children) }

  scope :visible, (lambda do |principal = User.current|
    public_views.or(private_views(principal))
  end)

  after_destroy :destroy_query_if_orphaned

  # Class names of view types that can be created as direct children of this
  # view. Each subclass gets its own list (no inheritance, no shared array)
  # so subclasses can safely `<<` without leaking into PersistedView or
  # sibling classes.
  def self.allowed_children
    @allowed_children ||= []
  end

  class << self
    attr_writer :allowed_children
  end

  # Resolves a (potentially user-supplied) class name to a view class, but only
  # if it is an allowed child of this view. Returns nil for any unknown or
  # forbidden name.
  def self.allowed_child_class(name)
    allowed_children.index_with(&:constantize)[name.to_s]
  end

  # Returns the query of this view or, if not set, the query of the parent view.
  def effective_query
    query || parent&.effective_query
  end

  # Whether the given user is permitted to see this view. Visibility rules
  # depend on the concrete view type (e.g. project membership, sharing,
  # public flag), so subclasses must implement this.
  def visible?(_user)
    raise SubclassResponsibilityError
  end

  private

  def parent_allows_this_child_class
    return if parent.nil?

    unless parent.class.allowed_children.include?(self.class.name)
      errors.add(:parent, :invalid_child_for_parent)
    end
  end

  # When this view is destroyed, also destroy its query unless another public
  # view still references it. Views belonging to the same owner that are also
  # going away (e.g. during user deletion) do not count as "still referencing"
  # since only public views keep a query alive.
  def destroy_query_if_orphaned
    return if query.nil?
    return if PersistedView.exists?(query:, public: true)

    query.destroy!
  end
end
