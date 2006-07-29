# Original Localization plugin for Rails can be found at:
# http://mir.aculo.us/articles/2005/10/03/ruby-on-rails-i18n-revisited
#
# Slightly edited by Jean-Philippe Lang
# - added @@langs and modified self.define method to maintain an array of available 
#   langages with labels, eg. { 'en' => 'English, 'fr' => 'French }
# - modified self.generate_l10n_file method to retrieve already translated strings
#

module Localization
  mattr_accessor :lang, :langs
  
  @@l10s = { :default => {} }
  @@lang = :default
  @@langs = {}
  
  def self._(string_to_localize, *args)
    translated = @@l10s[@@lang][string_to_localize] || string_to_localize
    return translated.call(*args).to_s  if translated.is_a? Proc
    if translated.is_a? Array
      translated = if translated.size == 3 
        translated[args[0]==0 ? 0 : (args[0]>1 ? 2 : 1)]
      else
        translated[args[0]>1 ? 1 : 0]
      end
    end
    sprintf translated, *args
  end
  
  def self.define(lang = :default, name = :default)
    @@l10s[lang] ||= {}
    @@langs[lang] = [ name ]
    yield @@l10s[lang]
  end
  
  def self.load
    Dir.glob("#{RAILS_ROOT}/lang/*.rb"){ |t| require t }
    Dir.glob("#{RAILS_ROOT}/lang/custom/*.rb"){ |t| require t }
  end
  
  # Generates a best-estimate l10n file from all views by
  # collecting calls to _() -- note: use the generated file only
  # as a start (this method is only guesstimating)
  def self.generate_l10n_file(lang)
    "Localization.define('en_US') do |l|\n" <<
    Dir.glob("#{RAILS_ROOT}/app/views/**/*.rhtml").collect do |f| 
      ["# #{f}"] << File.read(f).scan(/<%.*[^\w]_\s*[\(]+[\"\'](.*?)[\"\'][\)]+/)
    end.uniq.flatten.collect do |g|
      g.starts_with?('#') ? "\n  #{g}" : "  l.store '#{g}', '#{@@l10s[lang][g]}'"
    end.uniq.join("\n") << "\nend"
  end
  
end

class Object
  def _(*args); Localization._(*args); end
end