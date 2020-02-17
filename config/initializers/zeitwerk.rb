module OpenProject
  class Inflector < Zeitwerk::GemInflector
    # TODO: split up into a registry
    def camelize(basename, abspath)
      if basename =~ /\A(.*)_api\z/
        super($1, abspath) + 'API'
      elsif basename =~ /\Aoauth_(.*)\z/
        'OAuth' + super($1, abspath)
      elsif basename =~ /\A(.*)_oauth\z/
        super($1, abspath) + 'OAuth'
      elsif basename =~ /\A(.*)_sso\z/
        super($1, abspath) + 'SSO'
      elsif basename =~ /\Aar_(.*)\z/
        'AR' + super($1, abspath)
      elsif basename =~ /\Apdf_export\z/
        'PDFExport'
      elsif abspath =~ /open_project\/version(\.rb)?\z/
        "VERSION"
      else
        super
      end
    end
  end
end

Rails.autoloaders.each do |autoloader|
  autoloader.inflector = OpenProject::Inflector.new(__FILE__)
  autoloader.inflector.inflect(
    'api' => 'API',
    'rss' => 'RSS',
    'sha1' => 'SHA1',
    'oauth' => 'OAuth',
    'sso' => 'SSO',
    'csv' => 'CSV',
    'pdf' => 'PDF',
    'scm' => 'SCM',
    'imap' => 'IMAP',
    'pop3' => 'POP3',
    'openid_connect' => 'OpenIDConnect'
  )
end

# Instruct zeitwerk to ignore all the engine gems' lib initialization files
Rails.autoloaders.main.ignore(Rails.root.join('modules/*/lib/openproject-*.rb'))
Rails.autoloaders.main.ignore(Rails.root.join('lib/plugins'))
Rails.autoloaders.main.ignore(Rails.root.join('lib/generators'))
Rails.autoloaders.main.ignore(Bundler.bundle_path.join('**/*.rb'))
