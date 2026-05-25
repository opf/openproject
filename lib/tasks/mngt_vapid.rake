# frozen_string_literal: true

namespace :mngt do
  desc "Generate VAPID keys for Web Push — add output to your environment variables"
  task vapid_keygen: :environment do
    require "openssl"
    require "base64"

    ec  = OpenSSL::PKey::EC.generate("prime256v1")
    pub = Base64.urlsafe_encode64(ec.public_key.to_octet_string(:uncompressed), padding: false)
    prv = Base64.urlsafe_encode64(ec.private_key.to_s(2).rjust(32, "\x00"), padding: false)

    puts "Add to your environment (.env / docker-compose secrets):"
    puts "MNGT_VAPID_PUBLIC_KEY=#{pub}"
    puts "MNGT_VAPID_PRIVATE_KEY=#{prv}"
  end
end
