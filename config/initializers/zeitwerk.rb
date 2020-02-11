

# TODO: Token:Rss and Token::Api have been renamed to Token::RSS and Token::API. A migration needs to set the existing data accordingly

# frozen_string_literal: true

module OpenProject
  class Inflector < Zeitwerk::GemInflector
    def camelize(basename, abspath)
      if basename =~ /\A(.*)_api\z/
        super($1, abspath) + 'API'
      elsif basename =~ /\Aoauth_(.*)\z/
        'OAuth' + super($1, abspath)
      elsif basename =~ /\A(.*)_sso\z/
        super($1, abspath) + 'SSO'
      elsif basename =~ /\Aar_(.*)\z/
        'AR' + super($1, abspath)
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
    'scm' => 'SCM'
  )
end
