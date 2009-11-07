module CodeRay
module Scanners
  
  load :html
  
  # Original by Stefan Walk.
  class PHP < Scanner
    
    register_for :php
    file_extension 'php'
    
    KINDS_NOT_LOC = HTML::KINDS_NOT_LOC
    
    def setup
      @html_scanner = CodeRay.scanner :html, :tokens => @tokens, :keep_tokens => true, :keep_state => true
    end
    
    def reset_instance
      super
      @html_scanner.reset
    end
    
    module Words
      
      # according to http://www.php.net/manual/en/reserved.keywords.php
      KEYWORDS = %w[
        abstract and array as break case catch class clone const continue declare default do else elseif
        enddeclare endfor endforeach endif endswitch endwhile extends final for foreach function global
        goto if implements interface instanceof namespace new or private protected public static switch
        throw try use var while xor
        cfunction old_function
      ]
      
      TYPES = %w[ int integer float double bool boolean string array object resource ]
      
      LANGUAGE_CONSTRUCTS = %w[
        die echo empty exit eval include include_once isset list
        require require_once return print unset
      ]
      
      CLASSES = %w[ Directory stdClass  __PHP_Incomplete_Class exception php_user_filter Closure ]
      
      # according to http://php.net/quickref.php on 2009-04-21;
      # all functions with _ excluded (module functions) and selected additional functions
      BUILTIN_FUNCTIONS = %w[
        abs acos acosh addcslashes addslashes aggregate array arsort ascii2ebcdic asin asinh asort assert atan atan2
        atanh basename bcadd bccomp bcdiv bcmod bcmul bcpow bcpowmod bcscale bcsqrt bcsub bin2hex bindec
        bindtextdomain bzclose bzcompress bzdecompress bzerrno bzerror bzerrstr bzflush bzopen bzread bzwrite
        calculhmac ceil chdir checkdate checkdnsrr chgrp chmod chop chown chr chroot clearstatcache closedir closelog
        compact constant copy cos cosh count crc32 crypt current date dcgettext dcngettext deaggregate decbin dechex
        decoct define defined deg2rad delete dgettext die dirname diskfreespace dl dngettext doubleval each
        ebcdic2ascii echo empty end ereg eregi escapeshellarg escapeshellcmd eval exec exit exp explode expm1 extract
        fclose feof fflush fgetc fgetcsv fgets fgetss file fileatime filectime filegroup fileinode filemtime fileowner
        fileperms filepro filesize filetype floatval flock floor flush fmod fnmatch fopen fpassthru fprintf fputcsv
        fputs fread frenchtojd fscanf fseek fsockopen fstat ftell ftok ftruncate fwrite getallheaders getcwd getdate
        getenv gethostbyaddr gethostbyname gethostbynamel getimagesize getlastmod getmxrr getmygid getmyinode getmypid
        getmyuid getopt getprotobyname getprotobynumber getrandmax getrusage getservbyname getservbyport gettext
        gettimeofday gettype glob gmdate gmmktime gmstrftime gregoriantojd gzclose gzcompress gzdecode gzdeflate
        gzencode gzeof gzfile gzgetc gzgets gzgetss gzinflate gzopen gzpassthru gzputs gzread gzrewind gzseek gztell
        gzuncompress gzwrite hash header hebrev hebrevc hexdec htmlentities htmlspecialchars hypot iconv idate
        implode include intval ip2long iptcembed iptcparse isset
        jddayofweek jdmonthname jdtofrench jdtogregorian jdtojewish jdtojulian jdtounix jewishtojd join jpeg2wbmp
        juliantojd key krsort ksort lcfirst lchgrp lchown levenshtein link linkinfo list localeconv localtime log
        log10 log1p long2ip lstat ltrim mail main max md5 metaphone mhash microtime min mkdir mktime msql natcasesort
        natsort next ngettext nl2br nthmac octdec opendir openlog
        ord overload pack passthru pathinfo pclose pfsockopen phpcredits phpinfo phpversion pi png2wbmp popen pos pow
        prev print printf putenv quotemeta rad2deg rand range rawurldecode rawurlencode readdir readfile readgzfile
        readline readlink realpath recode rename require reset rewind rewinddir rmdir round rsort rtrim scandir
        serialize setcookie setlocale setrawcookie settype sha1 shuffle signeurlpaiement sin sinh sizeof sleep snmpget
        snmpgetnext snmprealwalk snmpset snmpwalk snmpwalkoid sort soundex split spliti sprintf sqrt srand sscanf stat
        strcasecmp strchr strcmp strcoll strcspn strftime stripcslashes stripos stripslashes stristr strlen
        strnatcasecmp strnatcmp strncasecmp strncmp strpbrk strpos strptime strrchr strrev strripos strrpos strspn
        strstr strtok strtolower strtotime strtoupper strtr strval substr symlink syslog system tan tanh tempnam
        textdomain time tmpfile touch trim uasort ucfirst ucwords uksort umask uniqid unixtojd unlink unpack
        unserialize unset urldecode urlencode usleep usort vfprintf virtual vprintf vsprintf wordwrap
        array_change_key_case array_chunk array_combine array_count_values array_diff array_diff_assoc
        array_diff_key array_diff_uassoc array_diff_ukey array_fill array_fill_keys array_filter array_flip
        array_intersect array_intersect_assoc array_intersect_key array_intersect_uassoc array_intersect_ukey
        array_key_exists array_keys array_map array_merge array_merge_recursive array_multisort array_pad
        array_pop array_product array_push array_rand array_reduce array_reverse array_search array_shift
        array_slice array_splice array_sum array_udiff array_udiff_assoc array_udiff_uassoc array_uintersect
        array_uintersect_assoc array_uintersect_uassoc array_unique array_unshift array_values array_walk
        array_walk_recursive
        assert_options base_convert base64_decode base64_encode
        chunk_split class_exists class_implements class_parents
        count_chars debug_backtrace debug_print_backtrace debug_zval_dump
        error_get_last error_log error_reporting extension_loaded
        file_exists file_get_contents file_put_contents load_file
        func_get_arg func_get_args func_num_args function_exists
        get_browser get_called_class get_cfg_var get_class get_class_methods get_class_vars
        get_current_user get_declared_classes get_declared_interfaces get_defined_constants
        get_defined_functions get_defined_vars get_extension_funcs get_headers get_html_translation_table
        get_include_path get_included_files get_loaded_extensions get_magic_quotes_gpc get_magic_quotes_runtime
        get_meta_tags get_object_vars get_parent_class get_required_filesget_resource_type
        gc_collect_cycles gc_disable gc_enable gc_enabled
        halt_compiler headers_list headers_sent highlight_file highlight_string
        html_entity_decode htmlspecialchars_decode
        in_array include_once inclued_get_data
        is_a is_array is_binary is_bool is_buffer is_callable is_dir is_double is_executable is_file is_finite
        is_float is_infinite is_int is_integer is_link is_long is_nan is_null is_numeric is_object is_readable
        is_real is_resource is_scalar is_soap_fault is_string is_subclass_of is_unicode is_uploaded_file
        is_writable is_writeable
        locale_get_default locale_set_default
        number_format override_function parse_str parse_url
        php_check_syntax php_ini_loaded_file php_ini_scanned_files php_logo_guid php_sapi_name
        php_strip_whitespace php_uname
        preg_filter preg_grep preg_last_error preg_match preg_match_all preg_quote preg_replace
        preg_replace_callback preg_split print_r
        require_once register_shutdown_function register_tick_function
        set_error_handler set_exception_handler set_file_buffer set_include_path
        set_magic_quotes_runtime set_time_limit shell_exec
        str_getcsv str_ireplace str_pad str_repeat str_replace str_rot13 str_shuffle str_split str_word_count
        strip_tags substr_compare substr_count substr_replace
        time_nanosleep time_sleep_until
        token_get_all token_name trigger_error
        unregister_tick_function use_soap_error_handler user_error
        utf8_decode utf8_encode var_dump var_export
        version_compare
        zend_logo_guid zend_thread_id zend_version
      ]
      # TODO: more built-in PHP functions?
      
      EXCEPTIONS = %w[
        E_ERROR E_WARNING E_PARSE E_NOTICE E_CORE_ERROR E_CORE_WARNING E_COMPILE_ERROR E_COMPILE_WARNING
        E_USER_ERROR E_USER_WARNING E_USER_NOTICE E_DEPRECATED E_USER_DEPRECATED E_ALL E_STRICT
      ]
      
      CONSTANTS = %w[
        null true false self parent
        __LINE__ __DIR__ __FILE__ __LINE__
        __CLASS__ __NAMESPACE__ __METHOD__ __FUNCTION__
        PHP_VERSION PHP_MAJOR_VERSION PHP_MINOR_VERSION PHP_RELEASE_VERSION PHP_VERSION_ID PHP_EXTRA_VERSION PHP_ZTS
        PHP_DEBUG PHP_MAXPATHLEN PHP_OS PHP_SAPI PHP_EOL PHP_INT_MAX PHP_INT_SIZE DEFAULT_INCLUDE_PATH
        PEAR_INSTALL_DIR PEAR_EXTENSION_DIR PHP_EXTENSION_DIR PHP_PREFIX PHP_BINDIR PHP_LIBDIR PHP_DATADIR
        PHP_SYSCONFDIR PHP_LOCALSTATEDIR PHP_CONFIG_FILE_PATH PHP_CONFIG_FILE_SCAN_DIR PHP_SHLIB_SUFFIX
        PHP_OUTPUT_HANDLER_START PHP_OUTPUT_HANDLER_CONT PHP_OUTPUT_HANDLER_END
        __COMPILER_HALT_OFFSET__
        EXTR_OVERWRITE EXTR_SKIP EXTR_PREFIX_SAME EXTR_PREFIX_ALL EXTR_PREFIX_INVALID EXTR_PREFIX_IF_EXISTS
        EXTR_IF_EXISTS SORT_ASC SORT_DESC SORT_REGULAR SORT_NUMERIC SORT_STRING CASE_LOWER CASE_UPPER COUNT_NORMAL
        COUNT_RECURSIVE ASSERT_ACTIVE ASSERT_CALLBACK ASSERT_BAIL ASSERT_WARNING ASSERT_QUIET_EVAL CONNECTION_ABORTED
        CONNECTION_NORMAL CONNECTION_TIMEOUT INI_USER INI_PERDIR INI_SYSTEM INI_ALL M_E M_LOG2E M_LOG10E M_LN2 M_LN10
        M_PI M_PI_2 M_PI_4 M_1_PI M_2_PI M_2_SQRTPI M_SQRT2 M_SQRT1_2 CRYPT_SALT_LENGTH CRYPT_STD_DES CRYPT_EXT_DES
        CRYPT_MD5 CRYPT_BLOWFISH DIRECTORY_SEPARATOR SEEK_SET SEEK_CUR SEEK_END LOCK_SH LOCK_EX LOCK_UN LOCK_NB
        HTML_SPECIALCHARS HTML_ENTITIES ENT_COMPAT ENT_QUOTES ENT_NOQUOTES INFO_GENERAL INFO_CREDITS
        INFO_CONFIGURATION INFO_MODULES INFO_ENVIRONMENT INFO_VARIABLES INFO_LICENSE INFO_ALL CREDITS_GROUP
        CREDITS_GENERAL CREDITS_SAPI CREDITS_MODULES CREDITS_DOCS CREDITS_FULLPAGE CREDITS_QA CREDITS_ALL STR_PAD_LEFT
        STR_PAD_RIGHT STR_PAD_BOTH PATHINFO_DIRNAME PATHINFO_BASENAME PATHINFO_EXTENSION PATH_SEPARATOR CHAR_MAX
        LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_ALL LC_MESSAGES ABDAY_1 ABDAY_2 ABDAY_3 ABDAY_4 ABDAY_5
        ABDAY_6 ABDAY_7 DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7 ABMON_1 ABMON_2 ABMON_3 ABMON_4 ABMON_5 ABMON_6
        ABMON_7 ABMON_8 ABMON_9 ABMON_10 ABMON_11 ABMON_12 MON_1 MON_2 MON_3 MON_4 MON_5 MON_6 MON_7 MON_8 MON_9
        MON_10 MON_11 MON_12 AM_STR PM_STR D_T_FMT D_FMT T_FMT T_FMT_AMPM ERA ERA_YEAR ERA_D_T_FMT ERA_D_FMT ERA_T_FMT
        ALT_DIGITS INT_CURR_SYMBOL CURRENCY_SYMBOL CRNCYSTR MON_DECIMAL_POINT MON_THOUSANDS_SEP MON_GROUPING
        POSITIVE_SIGN NEGATIVE_SIGN INT_FRAC_DIGITS FRAC_DIGITS P_CS_PRECEDES P_SEP_BY_SPACE N_CS_PRECEDES
        N_SEP_BY_SPACE P_SIGN_POSN N_SIGN_POSN DECIMAL_POINT RADIXCHAR THOUSANDS_SEP THOUSEP GROUPING YESEXPR NOEXPR
        YESSTR NOSTR CODESET LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG LOG_KERN
        LOG_USER LOG_MAIL LOG_DAEMON LOG_AUTH LOG_SYSLOG LOG_LPR LOG_NEWS LOG_UUCP LOG_CRON LOG_AUTHPRIV LOG_LOCAL0
        LOG_LOCAL1 LOG_LOCAL2 LOG_LOCAL3 LOG_LOCAL4 LOG_LOCAL5 LOG_LOCAL6 LOG_LOCAL7 LOG_PID LOG_CONS LOG_ODELAY
        LOG_NDELAY LOG_NOWAIT LOG_PERROR
      ]
      
      IDENT_KIND = CaseIgnoringWordList.new(:ident, true).
        add(KEYWORDS, :reserved).
        add(TYPES, :pre_type).
        add(LANGUAGE_CONSTRUCTS, :reserved).
        add(BUILTIN_FUNCTIONS, :predefined).
        add(CLASSES, :pre_constant).
        add(EXCEPTIONS, :exception).
        add(CONSTANTS, :pre_constant)
    end
    
    module RE
      
      PHP_START = /
        <script\s+[^>]*?language\s*=\s*"php"[^>]*?> |
        <script\s+[^>]*?language\s*=\s*'php'[^>]*?> |
        <\?php\d? |
        <\?(?!xml)
      /xi
      
      PHP_END = %r!
        </script> |
        \?>
      !xi
      
      HTML_INDICATOR = /<!DOCTYPE html|<(?:html|body|div|p)[> ]/i
      
      IDENTIFIER = /[a-z_\x7f-\xFF][a-z0-9_\x7f-\xFF]*/i
      VARIABLE = /\$#{IDENTIFIER}/
      
      OPERATOR = /
        \.(?!\d)=? |      # dot that is not decimal point, string concatenation
        && | \|\| |       # logic
        :: | -> | => |    # scope, member, dictionary
        \+\+ | -- |       # increment, decrement
        [,;?:()\[\]{}] |  # simple delimiters
        [-+*\/%&|^]=? |   # ordinary math, binary logic, assignment shortcuts
        [~@$] |           # whatever
        [=!]=?=? | <> |   # comparison and assignment
        <<=? | >>=? | [<>]=?  # comparison and shift
      /x
      
    end
    
    def scan_tokens tokens, options
      
      states = [:initial]
      if match?(RE::PHP_START) ||  # starts with <?
       (match?(/\s*<\S/) && exist?(RE::PHP_START)) || # starts with tag and contains <?
       exist?(RE::HTML_INDICATOR)
        # is PHP inside HTML, so start with HTML
      else
        states << :php
      end
      
      # heredocdelim = nil
      delimiter = nil
      
      until eos?
        
        match = nil
        kind = nil
        
        case states.last
        
        when :initial  # HTML
          if scan RE::PHP_START
            kind = :inline_delimiter
            states << :php
          else
            match = scan_until(/(?=#{RE::PHP_START})/o) || scan_until(/\z/)
            @html_scanner.tokenize match unless match.empty?
            next
          end
        
        when :php
          if scan RE::PHP_END
            kind = :inline_delimiter
            states = [:initial]
          
          elsif scan(/\s+/)
            kind = :space
          
          elsif scan(/ \/\* (?: .*? \*\/ | .* ) /mx)
            kind = :comment
          
          elsif scan(%r!(?://|#).*?(?=#{RE::PHP_END}|$)!o)
            kind = :comment
          
          elsif match = scan(RE::IDENTIFIER)
            kind = Words::IDENT_KIND[match]
            if kind == :ident && check(/:(?!:)/) #&& tokens[-2][0] == 'case'
              # FIXME: don't match a?b:c
              kind = :label
            elsif kind == :ident && match =~ /^[A-Z]/
              kind = :constant
            elsif kind == :reserved && match == 'class'
              states << :class_expected
            elsif kind == :reserved && match == 'function'
              states << :function_expected
            end
          
          elsif scan(/(?:\d+\.\d*|\d*\.\d+)(?:e[-+]?\d+)?|\d+e[-+]?\d+/i)
            kind = :float
          
          elsif scan(/0x[0-9a-fA-F]+/)
            kind = :hex
          
          elsif scan(/\d+/)
            kind = :integer
          
          elsif scan(/'/)
            tokens << [:open, :string]
            kind = :delimiter
            states.push :sqstring
          
          elsif match = scan(/["`]/)
            tokens << [:open, :string]
            delimiter = match
            kind = :delimiter
            states.push :dqstring
          
          # TODO: Heredocs
          # See http://de2.php.net/manual/en/language.types.string.php#language.types.string.syntax.heredoc
          elsif match = scan(/<<<(#{RE::IDENTIFIER})/o)
            tokens << [:open, :string]
            heredocdelim = Regexp.escape self[1]
            tokens << [match, :delimiter]
            next if eos?
            tokens << [scan_until(/\n(?=#{heredocdelim};?$)|\z/), :content]
            next if eos?
            tokens << [scan(/#{heredocdelim}/), :delimiter]
            tokens << [:close, :string]
            next
          
          elsif scan RE::VARIABLE
            kind = :local_variable
          
          elsif scan(/\{/)
            kind = :operator
            states.push :php
          
          elsif scan(/\}/)
            if states.size == 1
              kind = :error
            else
              states.pop
              if states.last.is_a?(::Array)
                delimiter = states.last[1]
                states[-1] = states.last[0]
                tokens << [matched, :delimiter]
                tokens << [:close, :inline]
                next
              else
                kind = :operator
              end
            end
          
          elsif scan(/#{RE::OPERATOR}/o)
            kind = :operator
          
          else
            getch
            kind = :error
          
          end
        
        when :sqstring
          if scan(/[^'\\]+/)
            kind = :content
          elsif scan(/'/)
            tokens << [matched, :delimiter]
            tokens << [:close, :string]
            delimiter = nil
            states.pop
            next
          elsif scan(/\\[\\'\n]/)
            kind = :char
          elsif scan(/\\./m)
            kind = :content
          elsif scan(/\\/)
            kind = :error
          end
        
        when :dqstring
          if scan(delimiter == '"' ? /[^"${\\]+/ : /[^`${\\]+/)
            kind = :content
          elsif scan(delimiter == '"' ? /"/ : /`/)
            tokens << [matched, :delimiter]
            tokens << [:close, :string]
            delimiter = nil
            states.pop
            next
          elsif scan(/\\(?:x[0-9a-fA-F]{2}|\d{3})/)
            kind = :char
          elsif scan(delimiter == '"' ? /\\["\\\nfnrtv]/ : /\\[`\\\nfnrtv]/)
            kind = :char
          elsif scan(/\\./m)
            kind = :content
          elsif scan(/\\/)
            kind = :error
          elsif match = scan(/#{RE::VARIABLE}/o)
            kind = :local_variable
            # $foo[bar] and $foo->bar kind of stuff
            # TODO: highlight tokens separately!
            if check(/\[#{RE::IDENTIFIER}\]/o)
              match << scan(/\[#{RE::IDENTIFIER}\]/o)
            elsif check(/\[/)
              match << scan(/\[#{RE::IDENTIFIER}?/o)
              kind = :error
            elsif check(/->#{RE::IDENTIFIER}/o)
              match << scan(/->#{RE::IDENTIFIER}/o)
            elsif check(/->/)
              match << scan(/->/)
              kind = :error
            end
          elsif match = scan(/\{/)
            if check(/\$/)
              kind = :delimiter
              states[-1] = [states.last, delimiter]
              delimiter = nil
              states.push :php
              tokens << [:open, :inline]
            else
              kind = :string
            end
          elsif scan(/\$\{#{RE::IDENTIFIER}\}/o)
            kind = :local_variable
          elsif scan(/\$/)
            kind = :content
          end
        
        when :class_expected
          if scan(/\s+/)
            kind = :space
          elsif match = scan(/#{RE::IDENTIFIER}/o)
            kind = :class
            states.pop
          else
            states.pop
            next
          end
        
        when :function_expected
          if scan(/\s+/)
            kind = :space
          elsif scan(/&/)
            kind = :operator
          elsif match = scan(/#{RE::IDENTIFIER}/o)
            kind = :function
            states.pop
          else
            states.pop
            next
          end
        
        else
          raise_inspect 'Unknown state!', tokens, states
        end
        
        match ||= matched
        if $DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens, states
        end
        raise_inspect 'Empty token', tokens, states unless match
        
        tokens << [match, kind]
        
      end
      
      tokens
    end
    
  end
  
end
end
