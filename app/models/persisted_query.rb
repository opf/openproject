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

class PersistedQuery < ApplicationRecord
  include Queries::BaseQuery
  include Queries::Serialization::Hash
  include ::Scopes::Scoped

  belongs_to :project, optional: true
  belongs_to :principal, optional: true, inverse_of: :persisted_queries

  has_many :views, class_name: "PersistedView",
                   as: :query,
                   dependent: :restrict_with_error,
                   inverse_of: :query

  has_many :ordered_entities, -> { order(position: :asc) },
           class_name: "OrderedPersistedQueryEntity",
           dependent: :destroy,
           inverse_of: :persisted_query

  validates :name, length: { maximum: 255, allow_nil: true }

  def self.inherited(subclass)
    super
    subclass.serialize :filters, coder: Queries::Serialization::Filters.new(subclass)
    subclass.serialize :orders, coder: Queries::Serialization::Orders.new(subclass)
    subclass.serialize :selects, coder: Queries::Serialization::Selects.new(subclass)
  end

  def self.register_query(&)
    Queries::Register.register(self, &)
  end

  def user
    principal if principal.is_a?(User)
  end

  def user=(user)
    self.principal = user
  end

  # Returns the query results. A `manual_elements` query draws from its
  # explicitly-ordered `ordered_entities` instead of its filters and orders
  def results
    return super unless manual_elements?

    entity_ids = ordered_entities.pluck(:entity_id)
    self.class.model.where(id: entity_ids).in_order_of(:id, entity_ids)
  end
end
