require Rails.root.join('config/constants/open_project/inflector')

OpenProject::Inflector.rule do |_, abspath|
  if abspath.match?(/open_project\/version(\.rb)?\z/) ||
    abspath.match?(/lib\/open_project\/\w+\/version(\.rb)?\z/)
    "VERSION"
  end
end

OpenProject::Inflector.rule do |basename, abspath|
  if basename =~ /\A(.*)_api\z/
    default_inflect($1, abspath) + 'API'
  end
end

OpenProject::Inflector.rule do |basename, abspath|
  if basename =~ /\Aar_(.*)\z/
    'AR' + default_inflect($1, abspath)
  end
end

OpenProject::Inflector.rule do |basename, abspath|
  if basename =~ /\Aoauth_(.*)\z/
    'OAuth' + default_inflect($1, abspath)
  elsif basename =~ /\A(.*)_oauth\z/
    default_inflect($1, abspath) + 'OAuth'
  elsif basename == 'oauth'
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
  'api' => 'API',
  'rss' => 'RSS',
  'sha1' => 'SHA1',
  'sso' => 'SSO',
  'csv' => 'CSV',
  'pdf' => 'PDF',
  'scm' => 'SCM',
  'imap' => 'IMAP',
  'pop3' => 'POP3',
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

# Comment in to enable zeitwerk logging.
# Rails.autoloaders.main.log!
