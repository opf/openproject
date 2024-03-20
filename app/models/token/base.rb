# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
# Adapted to fit needs for mOTP
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

module Token
  class Base < ApplicationRecord
    self.table_name = 'tokens'
    serialize :data, coder: ::Serializers::IndifferentHashSerializer

    # Hashed tokens belong to a user and are unique per type
    belongs_to :user

    # Create a plain and hashed value when creating a new token
    after_initialize :initialize_values

    # Ensure uniqueness of the token value
    validates :value, presence: true
    validates :value, uniqueness: true

    # Delete previous token of this type upon save
    before_save :delete_previous_token

    ##
    # Find a token from the token value
    def self.find_by_plaintext_value(input)
      find_by(value: input)
    end

    ##
    # Find tokens for the given user
    def self.for_user(user)
      where(user:)
    end

    ##
    # Generate a random hex token value
    def self.generate_token_value
      SecureRandom.hex(32)
    end

    protected

    ##
    # Allows only a single value of the token?
    def single_value?
      true
    end

    # Removes obsolete tokens (same user and action)
    def delete_previous_token
      if single_value? && user
        self.class.where(user_id: user.id, type:).delete_all
      end
    end

    def initialize_values
      if new_record? && !value.present?
        self.value = self.class.generate_token_value
      end
    end
  end
end
