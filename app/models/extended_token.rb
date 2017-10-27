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

class ExtendedToken < ActiveRecord::Base
  self.table_name = 'extended_tokens'

  belongs_to :user
  validates_uniqueness_of :value

  before_create :fill_in_values
  before_create :delete_previous_tokens
  after_save :destroy_expired_tokens

  #FIXME: is there no better solution than this?
  def self.validity_time
    1.day
  end

  def fill_in_values
    # FIXME: regenerate a new value if generated value is not unique
    self.value = self.class.generate_token_value if !self.value or self.value.empty?
    self.expires_on = Time.now + self.validity_time
  end

  def validity_time
    if !!self.expires_on && !!self.created_on
      self.expires_on - self.created_on
    else
      self.class.validity_time
    end
  end

  # Return true if token has expired
  def expired?
    return Time.now > self.created_on + self.validity_time
  end

  def self.create_and_return_value( params = {} )
    value = generate_token_value
    create( params.merge(:value => hash_function( value ) ))
    value
  end

  def self.find_by_plaintext_value( value )
    self.find_by_value( hash_function( value ) )
  end

  # Delete all expired tokens
  def self.destroy_expired
    self.where(["expires_on < ?", Time.now]).delete_all
  end

  private

  def self.generate_token_value
    ActiveSupport::SecureRandom.hex(20)
  end

  def self.hash_function( value )
    Digest::SHA1.hexdigest( value )
  end

  # Removes obsolete tokens (same user and action)
  def delete_previous_tokens
    if user
      self.class.where(user_id: user.id).delete_all
    end
  end

  def destroy_expired_tokens
    self.class.destroy_expired
  end
end