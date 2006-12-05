# Copyright (c) 2005-2006 David Barri

puts "GLoc v#{GLoc::VERSION} running in development mode. Strings can be modified at runtime."

module GLoc
  class << self
  
    alias :actual_add_localized_strings :add_localized_strings
    def add_localized_strings(lang, symbol_hash, override=true, strings_charset=nil)
      _verbose_msg {"dev::add_localized_strings #{lang}, [#{symbol_hash.size}], #{override}, #{strings_charset ? strings_charset : 'nil'}"}
      STATE.push [:hash, lang, {}.merge(symbol_hash), override, strings_charset]
      _force_refresh
    end
    
    alias :actual_load_localized_strings :load_localized_strings
    def load_localized_strings(dir=nil, override=true)
      _verbose_msg {"dev::load_localized_strings #{dir ? dir : 'nil'}, #{override}"}
      STATE.push [:dir, dir, override]
      _get_lang_file_list(dir).each {|filename| FILES[filename]= nil}
    end
  
    alias :actual_clear_strings :clear_strings
    def clear_strings(*languages)
      _verbose_msg {"dev::clear_strings #{languages.map{|l|l.to_s}.join(', ')}"}
      STATE.push [:clear, languages.clone]
      _force_refresh
    end
    
    alias :actual_clear_strings_except :clear_strings_except
    def clear_strings_except(*languages)
      _verbose_msg {"dev::clear_strings_except #{languages.map{|l|l.to_s}.join(', ')}"}
      STATE.push [:clear_except, languages.clone]
      _force_refresh
    end
    
    # Replace methods
    [:_l, :_l_rule, :_l_has_string?, :similar_language, :valid_languages, :valid_language?].each do |m|
      class_eval <<-EOB
        alias :actual_#{m} :#{m}
        def #{m}(*args)
          _assert_gloc_strings_up_to_date
          actual_#{m}(*args)
        end
      EOB
    end
    
    #-------------------------------------------------------------------------
    private
    
    STATE= []
    FILES= {}
  
    def _assert_gloc_strings_up_to_date
      changed= @@force_refresh
      
      # Check if any lang files have changed
      unless changed
        FILES.each_pair {|f,mtime|
          changed ||= (File.stat(f).mtime != mtime)
        }
      end

      return unless changed
      puts "GLoc reloading strings..."
      @@force_refresh= false
      
      # Update file timestamps
      FILES.each_key {|f|
        FILES[f]= File.stat(f).mtime
      }
      
      # Reload strings
      actual_clear_strings
      STATE.each {|s|
        case s[0]
        when :dir          then actual_load_localized_strings s[1], s[2]
        when :hash         then actual_add_localized_strings s[1], s[2], s[3], s[4]
        when :clear        then actual_clear_strings(*s[1])
        when :clear_except then actual_clear_strings_except(*s[1])
        else raise "Invalid state id: '#{s[0]}'"
        end
      }
      _verbose_msg :stats
    end
    
    @@force_refresh= false
    def _force_refresh
      @@force_refresh= true
    end
    
    alias :super_get_internal_state_vars :_get_internal_state_vars
    def _get_internal_state_vars
      super_get_internal_state_vars + [ STATE, FILES ]
    end
    
  end
end
