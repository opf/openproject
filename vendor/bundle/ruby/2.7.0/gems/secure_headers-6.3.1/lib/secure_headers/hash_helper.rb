# frozen_string_literal: true
require "base64"

module SecureHeaders
  module HashHelper
    def hash_source(inline_script, digest = :SHA256)
      base64_hashed_content = Base64.encode64(Digest.const_get(digest).digest(inline_script)).chomp
      "'#{digest.to_s.downcase}-#{base64_hashed_content}'"
    end
  end
end
