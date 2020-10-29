# coding: utf-8
# frozen_string_literal: true

class PDF::Reader

  # A null object security handler. Used when a PDF is unencrypted.
  class NullSecurityHandler

    def self.supports?(encrypt)
      encrypt.nil?
    end

    def decrypt(buf, _ref)
      buf
    end
  end
end
