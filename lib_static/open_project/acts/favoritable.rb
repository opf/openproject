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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Acts
    module Favoritable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Marks an ActiveRecord::Model as favoritable
        # A favoritable model has association with users (watchers) that marked it as favorite.
        #
        # This also creates the routes necessary for favoriting/unfavoriting by
        # adding the model's name to routes. This e.g leads to the following
        # routes when marking issues as watchable:
        #   POST:     projects/identifier/favorite
        #   DELETE:   projects/identifier/favorite
        #
        # acts_as_favoritable expects that the including module defines a +visible?(user)+ method,
        # as it's used to identify whether a user can actually favorite the object.
        def acts_as_favoritable # rubocop:disable Metrics/AbcSize
          return if included_modules.include?(InstanceMethods)

          class_eval do
            prepend InstanceMethods

            has_many :favorites, as: :favorited, dependent: :delete_all, validate: false
            has_many :favoriting_users, through: :favorites, source: :user, validate: false

            scope :favorited_by, ->(user_id) {
              includes(:favorites)
                .where(favorites: { user_id: })
            }

            scope :with_favorited_by_user, ->(user) {
              favorite = ::Favorite.arel_table

              join = arel_table
                      .join(favorite, Arel::Nodes::OuterJoin)
                      .on(
                        favorite[:favorited_type].eq(base_class.name),
                        favorite[:favorited_id].eq(arel_table[:id]),
                        favorite[:user_id].eq(user.id)
                      )
                      .join_sources

              select(arel_table[Arel.star], "(favorites.id IS NOT NULL) AS favorited").joins(join)
            }
          end

          Registry.add(self)
        end
      end

      module InstanceMethods
        def add_favoriting_user(user)
          return if favorites.exists?(user_id: user.id)

          favorites << Favorite.new(user:, favorited: self)
        end

        def remove_favoriting_user(user)
          favorites.where(user:).delete_all
        end

        def set_favorited(user, favorited: true)
          favorited ? add_favoriting_user(user) : remove_favoriting_user(user)
        end

        def favorited_by?(user)
          favorites.exists?(user:)
        end
      end
    end
  end
end
