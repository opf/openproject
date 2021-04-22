require Rails.root.join('config/constants/open_project/inflector')

OpenProject::Inflector.rule do |_, abspath|
  if abspath.match?(/open_project\/version(\.rb)?\z/) ||
     abspath.match?(/lib\/open_project\/\w+\/version(\.rb)?\z/)
    "VERSION"
  end
end

OpenProject::Inflector.rule do |basename, abspath|
  case basename
  when /\Aapi_(.*)\z/
    'API' + default_inflect($1, abspath)
  when /\A(.*)_api\z/
    default_inflect($1, abspath) + 'API'
  when 'api'
    'API'
  end
end

OpenProject::Inflector.rule do |basename, abspath|
  if basename =~ /\Aar_(.*)\z/
    'AR' + default_inflect($1, abspath)
  end
end

OpenProject::Inflector.rule do |basename, abspath|
  case basename
  when /\Aoauth_(.*)\z/
    'OAuth' + default_inflect($1, abspath)
  when /\A(.*)_oauth\z/
    default_inflect($1, abspath) + 'OAuth'
  when 'oauth'
    'OAuth'
  end
end

OpenProject::Inflector.rule do |basename, abspath|
  if basename =~ /\A(.*)_sso\z/
    default_inflect($1, abspath) + 'SSO'
  end
end

# Instruct zeitwerk to 'ignore' all the engine gems' lib initialization files.
# As it is complicated to return all the paths where such an initialization file might exist,
# we simply return the general OpenProject namespace for such files.
OpenProject::Inflector.rule do |_basename, abspath|
  if abspath =~ /openproject-\w+\/lib\/openproject-\w+.rb\z/ ||
     abspath =~ /modules\/\w+\/lib\/openproject-\w+.rb\z/
    'OpenProject'
  end
end

OpenProject::Inflector.inflection(
  'rss' => 'RSS',
  'sha1' => 'SHA1',
  'sso' => 'SSO',
  'csv' => 'CSV',
  'pdf' => 'PDF',
  'scm' => 'SCM',
  'imap' => 'IMAP',
  'pop3' => 'POP3',
  'cors' => 'CORS',
  'openid_connect' => 'OpenIDConnect',
  'pdf_export' => 'PDFExport'
)

Rails.autoloaders.each do |autoloader|
  autoloader.inflector = OpenProject::Inflector.new(__FILE__)
end

Rails.autoloaders.main.ignore(Rails.root.join('lib/plugins'))
Rails.autoloaders.main.ignore(Rails.root.join('lib/open_project/patches'))
Rails.autoloaders.main.ignore(Rails.root.join('lib/generators'))
Rails.autoloaders.main.ignore(Bundler.bundle_path.join('**/*.rb'))

Rails.application.reloader.to_prepare do
  contract_namespaces = Rails.autoloaders.main.autoloads.keys.grep(/contracts/).map do |x|
    matches = x.match(/contracts((?:\/[^\/]+)*)$/)
    constant_parts = matches.present? && matches[1].present? ? matches[1][1..].split('/') : nil

    next if constant_parts.nil?

    constant_parts.pop if constant_parts.last.end_with?('.rb')

    next if constant_parts.empty?

    constant = constant_parts.map(&:camelcase).join('::')

    if constant && Object.const_defined?(constant.to_sym)
      constant.constantize
    end
  end


  contract_namespaces.each do |mod|
    mod.define_singleton_method(:const_missing) do |name|
      if %i[UpdateService CreateService DeleteService].include?(name)
        service = Class.new("::BaseServices::#{name.to_s.gsub('Service', '')}".constantize)

        mod.const_set(name, service)

        return service
      else
        super(name)
      end
    end
  end
end

# Comment in to enable zeitwerk logging.
# Rails.autoloaders.main.log!
