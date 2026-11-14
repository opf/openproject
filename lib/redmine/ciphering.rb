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

module Redmine
  module Ciphering
    class << self
      def decrypt_text(text)
        if text && match = text.match(/\Aaes-256-cbc:(.+)\z/m)
          text = match[1]
          c = OpenSSL::Cipher.new("aes-256-cbc")
          e, iv = text.split("--").map { |s| Base64.decode64(s) }
          c.decrypt
          c.key = cipher_key
          c.iv = iv
          d = c.update(e)
          d << c.final
        else
          text
        end
      end

      def cipher_key
        key = OpenProject::Configuration["database_cipher_key"].to_s
        # With aes-256-cbc chosen to be the cipher,
        # keys need to be 32 bytes long. Ruby < 2.4 used to silently truncate the
        # key to the desired length but with
        # https://github.com/ruby/ruby/commit/ce635262f53b760284d56bb1027baebaaec175d1
        # we have to truncate it ourselves.
        key.blank? ? nil : Digest::SHA256.hexdigest(key)[0, 32]
      end
    end
  end
end
