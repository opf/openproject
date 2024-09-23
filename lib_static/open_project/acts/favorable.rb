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

module OpenProject
  module Acts
    module Favorable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Marks an ActiveRecord::Model as favorable
        # A favorable model has association with users (watchers) that marked it as favorite.
        #
        # This also creates the routes necessary for favoring/unfavoring by
        # adding the model's name to routes. This e.g leads to the following
        # routes when marking issues as watchable:
        #   POST:     projects/identifier/favorite
        #   DELETE:   projects/identifier/favorite
        #
        # acts_as_favorable expects that the including module defines a +visible?(user)+ method,
        # as it's used to identify whether a user can actually favorite the object.
        def acts_as_favorable # rubocop:disable Metrics/AbcSize
          return if included_modules.include?(InstanceMethods)

          class_eval do
            prepend InstanceMethods

            has_many :favorites, as: :favored, dependent: :delete_all, validate: false
            has_many :favoring_users, through: :favorites, source: :user, validate: false

            scope :favored_by, ->(user_id) {
              includes(:favorites)
                .where(favorites: { user_id: })
            }

            scope :with_favored_by_user, ->(user) {
              favorite = ::Favorite.arel_table

              join = arel_table
                      .join(favorite, Arel::Nodes::OuterJoin)
                      .on(
                        favorite[:favored_type].eq(base_class.name),
                        favorite[:favored_id].eq(arel_table[:id]),
                        favorite[:user_id].eq(user.id)
                      )
                      .join_sources

              select(arel_table[Arel.star], "(favorites.id IS NOT NULL) AS favored").joins(join)
            }
          end

          Registry.add(self)
        end
      end

      module InstanceMethods
        def add_favoring_user(user)
          return if favorites.exists?(user_id: user.id)

          favorites << Favorite.new(user:, favored: self)
        end

        def remove_favoring_user(user)
          favorites.where(user:).delete_all
        end

        def set_favored(user, favored: true)
          favored ? add_favoring_user(user) : remove_favoring_user(user)
        end

        def favored_by?(user)
          favorites.exists?(user:)
        end
      end
    end
  end
end
