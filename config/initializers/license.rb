begin
  data = File.read(Rails.root.join(".openproject-license.pub"))
  key = OpenSSL::PKey::RSA.new(data)
  OpenProject::License.key = key
rescue
  warn "WARNING: Missing .openproject-license.pub key"
end
