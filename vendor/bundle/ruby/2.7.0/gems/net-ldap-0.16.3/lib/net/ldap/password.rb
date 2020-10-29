# -*- ruby encoding: utf-8 -*-
require 'digest/sha1'
require 'digest/md5'
require 'base64'
require 'securerandom'

class Net::LDAP::Password
  class << self
    # Generate a password-hash suitable for inclusion in an LDAP attribute.
    # Pass a hash type as a symbol (:md5, :sha, :ssha) and a plaintext
    # password. This function will return a hashed representation.
    #
    #--
    # STUB: This is here to fulfill the requirements of an RFC, which
    # one?
    #
    # TODO:
    # * maybe salted-md5
    # * Should we provide sha1 as a synonym for sha1? I vote no because then
    #   should you also provide ssha1 for symmetry?
    #
    def generate(type, str)
      case type
      when :md5
         '{MD5}' + Base64.strict_encode64(Digest::MD5.digest(str))
      when :sha
         '{SHA}' + Base64.strict_encode64(Digest::SHA1.digest(str))
      when :ssha
         salt = SecureRandom.random_bytes(16)
         '{SSHA}' + Base64.strict_encode64(Digest::SHA1.digest(str + salt) + salt)
      else
         raise Net::LDAP::HashTypeUnsupportedError, "Unsupported password-hash type (#{type})"
      end
    end
  end
end
