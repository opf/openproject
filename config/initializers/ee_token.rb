begin
  data = File.read(Rails.root.join(".openproject-token.pub"))
  key = OpenSSL::PKey::RSA.new(data)
  OpenProject::Token.key = key
rescue
  warn "WARNING: Missing .openproject-token.pub key"
end
