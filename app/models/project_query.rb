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

class ProjectQuery < ApplicationRecord
  include Queries::BaseQuery
  include Queries::Serialization::Hash
  include HasMembers
  include ::Scopes::Scoped

  belongs_to :user

  acts_as_favorable

  serialize :filters, coder: Queries::Serialization::Filters.new(self)
  serialize :orders, coder: Queries::Serialization::Orders.new(self)
  serialize :selects, coder: Queries::Serialization::Selects.new(self)

  scope :public_lists, -> { where(public: true) }
  scope :private_lists, ->(user: User.current) { where(public: false, user:) }

  scope :visible, ->(user = User.current) {
                    allowed_to(user, :view_project_query)
                  }

  scopes :allowed_to

  def visible?(user = User.current)
    public? ||
    user == self.user ||
    user.allowed_in_project_query?(:view_project_query, self)
  end

  def editable?(user = User.current)
    # non public queries can only be edited by the owner
    (!public? && user == self.user) ||
    # public queries can be edited by users with the global permission (regardless of ownership)
    (public? && user.allowed_globally?(:manage_public_project_queries)) ||
    # or by users with the edit permission on the query
    user.allowed_in_project_query?(:edit_project_query, self)
  end

  def self.model
    Project
  end

  def default_scope
    # Cannot simply use .visible here as it would
    # filter out archived projects for everybody.
    if User.current.admin?
      super
    else
      # Directly appending the .visible scope adds a
      # distinct which then requires every column used e.g. for ordering
      # to be in select.
      super.where(id: Project.visible)
    end
  end

  def advanced_filters
    filters.reject do |filter|
      # Skip the name filter as we have it present as a permanent filter with a text input.
      filter.is_a?(Queries::Projects::Filters::NameAndIdentifierFilter)
    end
  end
end
