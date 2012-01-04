#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
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
          c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
          iv = c.random_iv
          c.encrypt
          c.key = cipher_key
          c.iv = iv
          e = c.update(text.to_s)
          e << c.final
          "aes-256-cbc:" + [e, iv].map {|v| Base64.encode64(v).strip}.join('--')
        end
      end

      def decrypt_text(text)
        if text && match = text.match(/\Aaes-256-cbc:(.+)\Z/)
          text = match[1]
          c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
          e, iv = text.split("--").map {|s| Base64.decode64(s)}
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
        key = Redmine::Configuration['database_cipher_key'].to_s
        key.blank? ? nil : Digest::SHA256.hexdigest(key)
      end
    end

    module ClassMethods
      def encrypt_all(attribute)
        transaction do
          all.each do |object|
            clear = object.send(attribute)
            object.send "#{attribute}=", clear
            raise(ActiveRecord::Rollback) unless object.save(false)
          end
        end ? true : false
      end

      def decrypt_all(attribute)
        transaction do
          all.each do |object|
            clear = object.send(attribute)
            object.write_attribute attribute, clear
            raise(ActiveRecord::Rollback) unless object.save(false)
          end
        end
      end ? true : false
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
