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

module Redmine
  module Ciphering
    def self.included(base)
      base.extend ClassMethods
    end

    class << self
      def encrypt_text(text)
        if cipher_key.blank?
          text
        else
          c = OpenSSL::Cipher.new("aes-256-cbc")
          iv = c.random_iv
          c.encrypt
          c.key = cipher_key
          c.iv = iv
          e = c.update(text.to_s)
          e << c.final
          "aes-256-cbc:" + [e, iv].map { |v| Base64.encode64(v).strip }.join("--")
        end
      end

      def decrypt_text(text)
        if text && match = text.match(/\Aaes-256-cbc:(.+)\Z/)
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

    module ClassMethods
      def encrypt_all(attribute)
        !!transaction do
          all.each do |object|
            clear = object.send(attribute)
            object.send :"#{attribute}=", clear
            raise(ActiveRecord::Rollback) unless object.save(validate: false)
          end
        end
      end

      def decrypt_all(attribute)
        !!transaction do
          all.each do |object|
            clear = object.send(attribute)
            object[attribute] = clear
            raise(ActiveRecord::Rollback) unless object.save(validate: false)
          end
        end
      end
    end

    private

    # Returns the value of the given ciphered attribute
    def read_ciphered_attribute(attribute)
      Redmine::Ciphering.decrypt_text(read_attribute(attribute))
    end

    # Sets the value of the given ciphered attribute
    def write_ciphered_attribute(attribute, value)
      write_attribute(attribute, Redmine::Ciphering.encrypt_text(value))
    end
  end
end
