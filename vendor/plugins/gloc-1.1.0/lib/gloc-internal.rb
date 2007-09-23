# Copyright (c) 2005-2006 David Barri

require 'iconv'
require 'gloc-version'

module GLoc
  class GLocError < StandardError #:nodoc:
  end
  class InvalidArgumentsError < GLocError #:nodoc:
  end
  class InvalidKeyError < GLocError #:nodoc:
  end
  class RuleNotFoundError < GLocError #:nodoc:
  end
  class StringNotFoundError < GLocError #:nodoc:
  end
  
  class << self
    private
    
    def _add_localized_data(lang, symbol_hash, override, target) #:nodoc:
      lang= lang.to_sym
      if override
        target[lang] ||= {}
        target[lang].merge!(symbol_hash)
      else
        symbol_hash.merge!(target[lang]) if target[lang]
        target[lang]= symbol_hash
      end
    end
    
    def _add_localized_strings(lang, symbol_hash, override=true, strings_charset=nil) #:nodoc:
      _charset_required
      
      # Convert all incoming strings to the gloc charset
      if strings_charset
        Iconv.open(get_charset(lang), strings_charset) do |i|
          symbol_hash.each_pair {|k,v| symbol_hash[k]= i.iconv(v)}
        end
      end

      # Convert rules
      rules= {}
      old_kcode= $KCODE
      begin
        $KCODE= 'u'
        Iconv.open(UTF_8, get_charset(lang)) do |i|
          symbol_hash.each {|k,v|
            if /^_gloc_rule_(.+)$/ =~ k.to_s
              v= i.iconv(v) if v
              v= '""' if v.nil?
              rules[$1.to_sym]= eval "Proc.new do #{v} end"
            end
          }
        end
      ensure
        $KCODE= old_kcode
      end
      rules.keys.each {|k| symbol_hash.delete "_gloc_rule_#{k}".to_sym}
      
      # Add new localized data
      LOWERCASE_LANGUAGES[lang.to_s.downcase]= lang
      _add_localized_data(lang, symbol_hash, override, LOCALIZED_STRINGS)
      _add_localized_data(lang, rules, override, RULES)
    end
    
    def _charset_required #:nodoc:
      set_charset UTF_8 unless CONFIG[:internal_charset]
    end
    
    def _get_internal_state_vars
      [ CONFIG, LOCALIZED_STRINGS, RULES, LOWERCASE_LANGUAGES ]
    end
    
    def _get_lang_file_list(dir) #:nodoc:
      dir= File.join(RAILS_ROOT,'{.,vendor/plugins/*}','lang') if dir.nil?
      Dir[File.join(dir,'*.{yaml,yml}')]
    end
    
    def _l(symbol, language, *arguments) #:nodoc:
      symbol= symbol.to_sym if symbol.is_a?(String)
      raise InvalidKeyError.new("Symbol or String expected as key.") unless symbol.kind_of?(Symbol)
      
      translation= LOCALIZED_STRINGS[language][symbol] rescue nil
      if translation.nil?
        raise StringNotFoundError.new("There is no key called '#{symbol}' in the #{language} strings.") if CONFIG[:raise_string_not_found_errors]
        translation= symbol.to_s
      end
      
      begin
        return translation % arguments
      rescue => e
        raise InvalidArgumentsError.new("Translation value #{translation.inspect} with arguments #{arguments.inspect} caused error '#{e.message}'")
      end
    end
  
    def _l_has_string?(symbol,lang) #:nodoc:
      symbol= symbol.to_sym if symbol.is_a?(String)
      LOCALIZED_STRINGS[lang].has_key?(symbol.to_sym) rescue false
    end

    def _l_rule(symbol,lang) #:nodoc:
      symbol= symbol.to_sym if symbol.is_a?(String)
      raise InvalidKeyError.new("Symbol or String expected as key.") unless symbol.kind_of?(Symbol)

      r= RULES[lang][symbol] rescue nil
      raise RuleNotFoundError.new("There is no rule called '#{symbol}' in the #{lang} rules.") if r.nil?
      r
    end
    
    def _verbose_msg(type=nil)
      return unless CONFIG[:verbose]
      x= case type
        when :stats
          x= valid_languages.map{|l| ":#{l}(#{LOCALIZED_STRINGS[l].size}/#{RULES[l].size})"}.sort.join(', ')
          "Current stats -- #{x}"
        else
          yield
        end
      puts "[GLoc] #{x}"
    end
    
    public :_l, :_l_has_string?, :_l_rule
  end
  
  private
  
  unless const_defined?(:LOCALIZED_STRINGS)
    LOCALIZED_STRINGS= {}
    RULES= {}
    LOWERCASE_LANGUAGES= {}
  end
  
end
