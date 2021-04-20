Settings::Definition.define do
  add :smtp_enable_starttls_auto,
      format: :boolean,
      api_name: 'smtpEnableStartTLSAuto',
      default: false,
      admin: true

  add :smtp_enable_starttls_auto,
      format: :boolean,
      api_name: 'smtpEnableStartTLSAuto',
      default: false,
      admin: true

  add :smtp_ssl,
      format: :boolean,
      api_name: 'smtpSSL',
      default: false,
      admin: true

  add :smtp_address,
      format: :string,
      default: '',
      admin: true

  add :smtp_port,
      format: :int,
      default: 587,
      admin: true

  add :edition,
      format: :string,
      default: 'standard',
      api: false,
      admin: true,
      writable: false
end

YAML::load(File.open(Rails.root.join('config/settings.yml'))).map do |name, config|
  Settings::Definition.add name,
                           format: config['format'],
                           default: config['default'],
                           serialized: config.fetch('serialized', false),
                           api: false
end
