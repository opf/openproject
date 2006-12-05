# Copyright (c) 2005-2006 David Barri

require 'yaml'
require 'gloc-internal'
require 'gloc-helpers'

module GLoc
  UTF_8= 'utf-8'
  SHIFT_JIS= 'sjis'
  EUC_JP= 'euc-jp'
  
  # This module will be included in both instances and classes of GLoc includees.
  # It is also included as class methods in the GLoc module itself.
  module InstanceMethods
    include Helpers
    
    # Returns a localized string.
    def l(symbol, *arguments)
      return GLoc._l(symbol,current_language,*arguments)
    end
  
    # Returns a localized string in a specified language.
    # This does not effect <tt>current_language</tt>.
    def ll(lang, symbol, *arguments)
      return GLoc._l(symbol,lang.to_sym,*arguments)
    end
    
    # Returns a localized string if the argument is a Symbol, else just returns the argument.
    def ltry(possible_key)
      possible_key.is_a?(Symbol) ? l(possible_key) : possible_key
    end
    
    # Uses the default GLoc rule to return a localized string.
    # See lwr_() for more info.
    def lwr(symbol, *arguments)
      lwr_(:default, symbol, *arguments)
    end
    
    # Uses a <em>rule</em> to return a localized string.
    # A rule is a function that uses specified arguments to return a localization key prefix.
    # The prefix is appended to the localization key originally specified, to create a new key which
    # is then used to lookup a localized string.
    def lwr_(rule, symbol, *arguments)
      GLoc._l("#{symbol}#{GLoc::_l_rule(rule,current_language).call(*arguments)}",current_language,*arguments)
    end

    # Returns <tt>true</tt> if a localized string with the specified key exists.
    def l_has_string?(symbol)
      return GLoc._l_has_string?(symbol,current_language)
    end
    
    # Sets the current language for this instance/class.
    # Setting the language of a class effects all instances unless the instance has its own language defined.
    def set_language(language)
      @gloc_language= language.nil? ? nil : language.to_sym
    end

    # Sets the current language if the language passed is a valid language.
    # If the language was valid, this method returns <tt>true</tt> else it will return <tt>false</tt>.
    # Note that <tt>nil</tt> is not a valid language.
    # See set_language(language) for more info.
    def set_language_if_valid(language)
      if GLoc.valid_language?(language)
        set_language(language)
        true
      else
        false
      end
    end
  end
  
  #---------------------------------------------------------------------------
  # Instance
  
  include ::GLoc::InstanceMethods
  # Returns the instance-level current language, or if not set, returns the class-level current language.
  def current_language
    @gloc_language || self.class.current_language
  end
  
  #---------------------------------------------------------------------------
  # Class
  
  # All classes/modules that include GLoc will also gain these class methods.
  # Notice that the GLoc::InstanceMethods module is also included.
  module ClassMethods
    include ::GLoc::InstanceMethods
    # Returns the current language, or if not set, returns the GLoc current language.
    def current_language
      @gloc_language || GLoc.current_language
    end
  end
  
  def self.included(target) #:nodoc:
    super
    class << target
      include ::GLoc::ClassMethods
    end
  end
  
  #---------------------------------------------------------------------------
  # GLoc module
  
  class << self
    include ::GLoc::InstanceMethods
    
    # Returns the default language
    def current_language
      GLoc::CONFIG[:default_language]
    end
    
    # Adds a collection of localized strings to the in-memory string store.
    def add_localized_strings(lang, symbol_hash, override=true, strings_charset=nil)
      _verbose_msg {"Adding #{symbol_hash.size} #{lang} strings."}
      _add_localized_strings(lang, symbol_hash, override, strings_charset)
      _verbose_msg :stats
    end
    
    # Creates a backup of the internal state of GLoc (ie. strings, langs, rules, config)
    # and optionally clears everything.
    def backup_state(clear=false)
      s= _get_internal_state_vars.map{|o| o.clone}
      _get_internal_state_vars.each{|o| o.clear} if clear
      s
    end
    
    # Removes all localized strings from memory, either of a certain language (or languages),
    # or entirely.
    def clear_strings(*languages)
      if languages.empty?
        _verbose_msg {"Clearing all strings"}
        LOCALIZED_STRINGS.clear
        LOWERCASE_LANGUAGES.clear
      else
        languages.each {|l|
          _verbose_msg {"Clearing :#{l} strings"}
          l= l.to_sym
          LOCALIZED_STRINGS.delete l
          LOWERCASE_LANGUAGES.each_pair {|k,v| LOWERCASE_LANGUAGES.delete k if v == l}
        }
      end
    end
    alias :_clear_strings :clear_strings
    
    # Removes all localized strings from memory, except for those of certain specified languages.
    def clear_strings_except(*languages)
      clear= (LOCALIZED_STRINGS.keys - languages)
      _clear_strings(*clear) unless clear.empty?
    end
    
    # Returns the charset used to store localized strings in memory.
    def get_charset(lang)
      CONFIG[:internal_charset_per_lang][lang] || CONFIG[:internal_charset]
    end
    
    # Returns a GLoc configuration value.
    def get_config(key)
      CONFIG[key]
    end
    
    # Loads the localized strings that are included in the GLoc library.
    def load_gloc_default_localized_strings(override=false)
      GLoc.load_localized_strings "#{File.dirname(__FILE__)}/../lang", override
    end
    
    # Loads localized strings from all yml files in the specifed directory.
    def load_localized_strings(dir=nil, override=true)
      _charset_required
      _get_lang_file_list(dir).each {|filename|
        
        # Load file
        raw_hash = YAML::load(File.read(filename))
        raw_hash={} unless raw_hash.kind_of?(Hash)
        filename =~ /([^\/\\]+)\.ya?ml$/
        lang = $1.to_sym
        file_charset = raw_hash['file_charset'] || UTF_8
  
        # Convert string keys to symbols
        dest_charset= get_charset(lang)
        _verbose_msg {"Reading file #{filename} [charset: #{file_charset} --> #{dest_charset}]"}
        symbol_hash = {}
        Iconv.open(dest_charset, file_charset) do |i|
          raw_hash.each {|key, value|
            symbol_hash[key.to_sym] = i.iconv(value)
          }
        end
  
        # Add strings to repos
        _add_localized_strings(lang, symbol_hash, override)
      }
      _verbose_msg :stats
    end
    
    # Restores a backup of GLoc's internal state that was made with backup_state.
    def restore_state(state)
      _get_internal_state_vars.each do |o|
        o.clear
        o.send o.respond_to?(:merge!) ? :merge! : :concat, state.shift
      end
    end
    
    # Sets the charset used to internally store localized strings.
    # You can set the charset to use for a specific language or languages,
    # or if none are specified the charset for ALL localized strings will be set.
    def set_charset(new_charset, *langs)
      CONFIG[:internal_charset_per_lang] ||= {}
      
      # Convert symbol shortcuts
      if new_charset.is_a?(Symbol)
        new_charset= case new_charset
          when :utf8, :utf_8 then UTF_8
          when :sjis, :shift_jis, :shiftjis then SHIFT_JIS
          when :eucjp, :euc_jp then EUC_JP
          else new_charset.to_s
          end
      end
      
      # Convert existing strings
      (langs.empty? ? LOCALIZED_STRINGS.keys : langs).each do |lang|
        cur_charset= get_charset(lang)
        if cur_charset && new_charset != cur_charset
          _verbose_msg {"Converting :#{lang} strings from #{cur_charset} to #{new_charset}"}
          Iconv.open(new_charset, cur_charset) do |i|
            bundle= LOCALIZED_STRINGS[lang]
            bundle.each_pair {|k,v| bundle[k]= i.iconv(v)}
          end
        end
      end
      
      # Set new charset value
      if langs.empty?
        _verbose_msg {"Setting GLoc charset for all languages to #{new_charset}"}
        CONFIG[:internal_charset]= new_charset
        CONFIG[:internal_charset_per_lang].clear
      else
        langs.each do |lang|
          _verbose_msg {"Setting GLoc charset for :#{lang} strings to #{new_charset}"}
          CONFIG[:internal_charset_per_lang][lang]= new_charset
        end
      end
    end

    # Sets GLoc configuration values.
    def set_config(hash)
      CONFIG.merge! hash
    end
    
    # Sets the $KCODE global variable according to a specified charset, or else the
    # current default charset for the default language.
    def set_kcode(charset=nil)
      _charset_required
      charset ||= get_charset(current_language)
      $KCODE= case charset
        when UTF_8 then 'u'
        when SHIFT_JIS then 's'
        when EUC_JP then 'e'
        else 'n'
        end
      _verbose_msg {"$KCODE set to #{$KCODE}"}
    end
    
    # Tries to find a valid language that is similar to the argument passed.
    # Eg. :en, :en_au, :EN_US are all similar languages.
    # Returns <tt>nil</tt> if no similar languages are found.
    def similar_language(lang)
      return nil if lang.nil?
      return lang.to_sym if valid_language?(lang)
      # Check lowercase without dashes
      lang= lang.to_s.downcase.gsub('-','_')
      return LOWERCASE_LANGUAGES[lang] if LOWERCASE_LANGUAGES.has_key?(lang)
      # Check without dialect
      if lang.to_s =~ /^([a-z]+?)[^a-z].*/
        lang= $1
        return LOWERCASE_LANGUAGES[lang] if LOWERCASE_LANGUAGES.has_key?(lang)
      end
      # Check other dialects
      lang= "#{lang}_"
      LOWERCASE_LANGUAGES.keys.each {|k| return LOWERCASE_LANGUAGES[k] if k.starts_with?(lang)}
      # Nothing found
      nil
    end
    
    # Returns an array of (currently) valid languages (ie. languages for which localized data exists).
    def valid_languages
      LOCALIZED_STRINGS.keys
    end
    
    # Returns <tt>true</tt> if there are any localized strings for a specified language.
    # Note that although <tt>set_langauge nil</tt> is perfectly valid, <tt>nil</tt> is not a valid language.
    def valid_language?(language)
      LOCALIZED_STRINGS.has_key? language.to_sym rescue false
    end
  end
end
