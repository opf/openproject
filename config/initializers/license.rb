begin
  public_key_file = File.read(Rails.root.join(".license_encryption_key.pub"))
  public_key = OpenSSL::PKey::RSA.new(public_key_file)
  OpenProject::License.key = public_key
rescue
  warn "WARNING: No valid license encryption key provided."
end
