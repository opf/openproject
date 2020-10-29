# frozen_string_literal: true

# encryption.rb : Implements encrypted PDF and access permissions.
#
# Copyright August 2008, Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'digest/md5'

require_relative 'security/arcfour'

module Prawn
  class Document
    # Implements PDF encryption (password protection and permissions) as
    # specified in the PDF Reference, version 1.3, section 3.5 "Encryption".
    module Security
      # @group Experimental API

      # Encrypts the document, to protect confidential data or control
      # modifications to the document. The encryption algorithm used is
      # detailed in the PDF Reference 1.3, section 3.5 "Encryption", and it is
      # implemented by all major PDF readers.
      #
      # +options+ can contain the following:
      #
      # <tt>:user_password</tt>:: Password required to open the document. If
      #                           this is omitted or empty, no password will be
      #                           required. The document will still be
      #                           encrypted, but anyone can read it.
      #
      # <tt>:owner_password</tt>:: Password required to make modifications to
      #                            the document or change or override its
      #                            permissions. If this is set to
      #                            <tt>:random</tt>, a random password will be
      #                            used; this can be useful if you never want
      #                            users to be able to override the document
      #                            permissions.
      #
      # <tt>:permissions</tt>:: A hash mapping permission symbols (see below) to
      #                         <tt>true</tt> or <tt>false</tt>. True means
      #                         "permitted", and false means "not permitted".
      #                         All permissions default to <tt>true</tt>.
      #
      # The following permissions can be specified:
      #
      # <tt>:print_document</tt>:: Print document.
      #
      # <tt>:modify_contents</tt>:: Modify contents of document (other than text
      #                             annotations and interactive form fields).
      #
      # <tt>:copy_contents</tt>:: Copy text and graphics from document.
      #
      # <tt>:modify_annotations</tt>:: Add or modify text annotations and
      #                                interactive form fields.
      #
      # == Examples
      #
      # Deny printing to everyone, but allow anyone to open without a password:
      #
      #   encrypt_document :permissions => { :print_document => false },
      #                    :owner_password => :random
      #
      # Set a user and owner password on the document, with full permissions for
      # both the user and the owner:
      #
      #   encrypt_document :user_password => 'foo', :owner_password => 'bar'
      #
      # Set no passwords, grant all permissions (This is useful because the
      # default in some readers, if no permissions are specified, is "deny"):
      #
      #   encrypt_document
      #
      # == Caveats
      #
      # * The encryption used is weak; the key is password-derived and is
      #   limited to 40 bits, due to US export controls in effect at the time
      #   the PDF standard was written.
      #
      # * There is nothing technologically requiring PDF readers to respect the
      #   permissions embedded in a document. Many PDF readers do not.
      #
      # * In short, you have <b>no security at all</b> against a moderately
      #   motivated person. Don't use this for anything super-serious. This is
      #   not a limitation of Prawn, but is rather a built-in limitation of the
      #   PDF format.
      #
      def encrypt_document(options = {})
        Prawn.verify_options %i[user_password owner_password permissions],
          options
        @user_password = options.delete(:user_password) || ''

        @owner_password = options.delete(:owner_password) || @user_password
        if @owner_password == :random
          # Generate a completely ridiculous password
          @owner_password = (1..32).map { rand(256) }.pack('c*')
        end

        self.permissions = options.delete(:permissions) || {}

        # Shove the necessary entries in the trailer and enable encryption.
        state.trailer[:Encrypt] = encryption_dictionary
        state.encrypt = true
        state.encryption_key = user_encryption_key
      end

      # Encrypts the given string under the given key, also requiring the
      # object ID and generation number of the reference.
      # See Algorithm 3.1.
      def self.encrypt_string(str, key, id, gen)
        # Convert ID and Gen number into little-endian truncated byte strings
        id = [id].pack('V')[0, 3]
        gen = [gen].pack('V')[0, 2]
        extended_key = "#{key}#{id}#{gen}"

        # Compute the RC4 key from the extended key and perform the encryption
        rc4_key = Digest::MD5.digest(extended_key)[0, 10]
        Arcfour.new(rc4_key).encrypt(str)
      end

      private

      # Provides the values for the trailer encryption dictionary.
      def encryption_dictionary
        {
          Filter: :Standard, # default PDF security handler
          V: 1,         # "Algorithm 3.1", PDF reference 1.3
          R: 2,         # Revision 2 of the algorithm
          O: PDF::Core::ByteString.new(owner_password_hash),
          U: PDF::Core::ByteString.new(user_password_hash),
          P: permissions_value
        }
      end

      # Flags in the permissions word, numbered as LSB = 1
      PERMISSIONS_BITS = {
        print_document: 3,
        modify_contents: 4,
        copy_contents: 5,
        modify_annotations: 6
      }.freeze
      private_constant :PERMISSIONS_BITS

      FULL_PERMISSIONS = 0b1111_1111_1111_1111_1111_1111_1111_1111
      private_constant :FULL_PERMISSIONS

      def permissions=(perms = {})
        @permissions ||= FULL_PERMISSIONS
        perms.each do |key, value|
          unless PERMISSIONS_BITS[key]
            raise(
              ArgumentError,
              "Unknown permission :#{key}. Valid options: " +
                PERMISSIONS_BITS.keys.map(&:inspect).join(', ')
            )
          end

          # 0-based bit number, from LSB
          bit_position = PERMISSIONS_BITS[key] - 1

          if value # set bit
            @permissions |= (1 << bit_position)
          else # clear bit
            @permissions &= ~(1 << bit_position)
          end
        end
      end

      def permissions_value
        @permissions || FULL_PERMISSIONS
      end

      PASSWORD_PADDING =
        '28BF4E5E4E758A4164004E56FFFA01082E2E00B6D0683E802F0CA9FE6453697A'
          .scan(/../).map { |x| x.to_i(16) }.pack('c*')

      # Pads or truncates a password to 32 bytes as per Alg 3.2.
      def pad_password(password)
        password = password[0, 32]
        password + PASSWORD_PADDING[0, 32 - password.length]
      end

      def user_encryption_key
        @user_encryption_key ||= begin
          md5 = Digest::MD5.new
          md5 << pad_password(@user_password)
          md5 << owner_password_hash
          md5 << [permissions_value].pack('V')
          md5.digest[0, 5]
        end
      end

      # The O (owner) value in the encryption dictionary. Algorithm 3.3.
      def owner_password_hash
        @owner_password_hash ||= begin
          key = Digest::MD5.digest(pad_password(@owner_password))[0, 5]
          Arcfour.new(key).encrypt(pad_password(@user_password))
        end
      end

      # The U (user) value in the encryption dictionary. Algorithm 3.4.
      def user_password_hash
        Arcfour.new(user_encryption_key).encrypt(PASSWORD_PADDING)
      end
    end
  end
end

# @private
module PDF
  module Core
    module_function

    # Like pdf_object, but returns an encrypted result if required.
    # For direct objects, requires the object identifier and generation number
    # from the indirect object referencing obj.
    #
    # @private
    def encrypted_pdf_object(obj, key, id, gen, in_content_stream = false)
      case obj
      when Array
        '[' + obj.map do |e|
          encrypted_pdf_object(e, key, id, gen, in_content_stream)
        end.join(' ') + ']'
      when LiteralString
        obj = ByteString.new(
          Prawn::Document::Security.encrypt_string(obj, key, id, gen)
        ).gsub(/[\\\n\(\)]/) { |m| "\\#{m}" }
        "(#{obj})"
      when Time
        obj = obj.strftime('D:%Y%m%d%H%M%S%z').chop.chop + "'00'"
        obj = ByteString.new(
          Prawn::Document::Security.encrypt_string(obj, key, id, gen)
        ).gsub(/[\\\n\(\)]/) { |m| "\\#{m}" }
        "(#{obj})"
      when String
        pdf_object(
          ByteString.new(
            Prawn::Document::Security.encrypt_string(obj, key, id, gen)
          ),
          in_content_stream
        )
      when ::Hash
        '<< ' +
          obj.map do |k, v|
            unless k.is_a?(String) || k.is_a?(Symbol)
              raise PDF::Core::Errors::FailedObjectConversion,
                'A PDF Dictionary must be keyed by names'
            end
            pdf_object(k.to_sym, in_content_stream) + ' ' +
              encrypted_pdf_object(v, key, id, gen, in_content_stream) + "\n"
          end.join('') +
          '>>'
      when NameTree::Value
        pdf_object(obj.name) + ' ' +
          encrypted_pdf_object(obj.value, key, id, gen, in_content_stream)
      when PDF::Core::OutlineRoot, PDF::Core::OutlineItem
        encrypted_pdf_object(obj.to_hash, key, id, gen, in_content_stream)
      else # delegate back to pdf_object
        pdf_object(obj, in_content_stream)
      end
    end

    # @private
    class Stream
      def encrypted_object(key, id, gen)
        if filtered_stream
          "stream\n" +
            Prawn::Document::Security.encrypt_string(
              filtered_stream, key, id, gen
            ) + "\nendstream\n"
        else
          ''
        end
      end
    end

    # @private
    class Reference
      # Returns the object definition for the object this references, keyed from
      # +key+.
      def encrypted_object(key)
        @on_encode&.call(self)

        output = +"#{@identifier} #{gen} obj\n"
        if @stream.empty?
          output <<
            PDF::Core.encrypted_pdf_object(data, key, @identifier, gen) << "\n"
        else
          output << PDF::Core.encrypted_pdf_object(
            data.merge(@stream.data), key, @identifier, gen
          ) << "\n" <<
            @stream.encrypted_object(key, @identifier, gen)
        end

        output << "endobj\n"
      end
    end
  end
end
