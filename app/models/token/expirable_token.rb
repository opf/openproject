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
  module ExpirableToken
    extend ActiveSupport::Concern

    included do
      # Set the expiration time
      before_create :set_expiration_time

      # Remove outdated token
      after_save :delete_expired_tokens

      def valid_plaintext?(input)
        return false if expired?
        super
      end

      def expired?
        expires_on && Time.now > expires_on
      end

      def validity_time
        self.class.validity_time
      end

      ##
      # Set the expiration column
      def set_expiration_time
        self.expires_on = Time.now + validity_time
      end

      # Delete all expired tokens
      def delete_expired_tokens
        self.class.where(["expires_on < ?", Time.now]).delete_all
      end
    end

    module ClassMethods

      ##
      # Return a scope of active tokens
      def not_expired
        where(["expires_on > ?", Time.now])
      end
    end
  end
end
