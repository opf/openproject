# encoding: UTF-8

module Stringex
  module Localization
    module ConversionExpressions
      ABBREVIATION = /(\s|\(|^)([[:alpha:]](\.[[:alpha:]])+(\.?)[[:alpha:]]*(\s|\)|$))/

      ACCENTED_HTML_ENTITY = /&([A-Za-z])(grave|acute|circ|tilde|uml|ring|cedil|slash);/

      APOSTROPHE = /(^|[[:alpha:]])'|`([[:alpha:]]|$)/

      CHARACTERS =  {
        and:      /\s*&\s*/,
        at:       /\s*@\s*/,
        degrees:  /\s*°\s*/,
        divide:   /\s*÷\s*/,
        dot:      /(\S|^)\.(\S)/,
        ellipsis: /\s*\.{3,}\s*/,
        equals:   /\s*=\s*/,
        number:   /\s*#/,
        percent:  /\s*%\s*/,
        plus:     /\s*\+\s*/,
        slash:    /\s*(\\|\/|／)\s*/,
        star:     /\s*\*\s*/,
      }

      # Things that just get converted to spaces
      CLEANUP_CHARACTERS = /[\.,:;(){}\[\]\?!\^'ʼ"`~_\|<>]/
      CLEANUP_HTML_ENTITIES = /&[^;]+;/

      CURRENCIES_SUPPORTED_SIMPLE = {
        generic: /¤/,
        dollars: /\$/,
        euros:   /€/,
        pounds:  /£/,
        yen:     /¥/,
        reais:   /R\$/
      }
      CURRENCIES_SUPPORTED_COMPLEX = {
        dollars: :dollars_cents,
        euros:   :euros_cents,
        pounds:  :pounds_pence,
        reais:   :reais_cents
      }
      CURRENCIES_SUPPORTED = Regexp.new(CURRENCIES_SUPPORTED_SIMPLE.values.join('|'))
      CURRENCIES_SIMPLE = CURRENCIES_SUPPORTED_SIMPLE.inject({}) do |hash, content|
        key, expression = content
        hash[key] = /(?:\s|^)#{expression}(\d*)(?:\s|$)/
        hash
      end
      CURRENCIES_COMPLEX = CURRENCIES_SUPPORTED_SIMPLE.inject({}) do |hash, content|
        key, expression = content
        # Do we really need to not worry about complex currencies if there are none for the currency?
        complex_key = CURRENCIES_SUPPORTED_COMPLEX[key]
        if complex_key
          hash[complex_key] = /(?:\s|^)#{expression}(\d+)\.(\d+)(?:\s|$)/
        end
        hash
      end
      CURRENCIES = CURRENCIES_SIMPLE.merge(CURRENCIES_COMPLEX)

      HTML_ENTITIES = Proc.new(){
        base = {
          amp:          %w{#38 amp},
          cent:         %w{#162 cent},
          copy:         %w{#169 copy},
          deg:          %w{#176 deg},
          divide:       %w{#247 divide},
          double_quote: %w{#34 #822[012] quot ldquo rdquo dbquo},
          ellipsis:     %w{#8230 hellip},
          en_dash:      %w{#8211 ndash},
          em_dash:      %w{#8212 mdash},
          frac14:       %w{#188 frac14},
          frac12:       %w{#189 frac12},
          frac34:       %w{#190 frac34},
          gt:           %w{#62 gt},
          lt:           %w{#60 lt},
          nbsp:         %w{#160 nbsp},
          pound:        %w{#163 pound},
          reg:          %w{#174 reg},
          single_quote: %w{#39 #821[678] apos lsquo rsquo sbquo},
          times:        %w{#215 times},
          trade:        %w{#8482 trade},
          yen:          %w{#165 yen},
        }
        base.inject({}) do |hash, content|
          key, expression = content
          hash[key] = /&(#{expression.join('|')});/
          hash
        end
      }.call

      HTML_TAG = Proc.new(){
        name = /[\w:-]+/
        value = /([A-Za-z0-9]+|('[^']*?'|"[^"]*?"))/
        attr = /(#{name}(\s*=\s*#{value})?)/
        /<[!\/?\[]?(#{name}|--)(\s+(#{attr}(\s+#{attr})*))?\s*([!\/?\]]+|--)?>/
      }.call

      SMART_PUNCTUATION = {
        /(“|”|\302\223|\302\224|\303\222|\303\223)/ => '"',
        /(‘|’|\302\221|\302\222|\303\225)/ => "'",
        /…/ => "...",
      }

      UNREADABLE_CONTROL_CHARACTERS = /[[:cntrl:]]/

      # Ordered by denominator then numerator of the value
      VULGAR_FRACTIONS = {
        half:          /(&#189;|&frac12;|½)/,
        one_third:     /(&#8531;|⅓)/,
        two_thirds:    /(&#8532;|⅔)/,
        one_fourth:    /(&#188;|&frac14;|¼)/,
        three_fourths: /(&#190;|&frac34;|¾)/,
        one_fifth:     /(&#8533;|⅕)/,
        two_fifths:    /(&#8534;|⅖)/,
        three_fifths:  /(&#8535;|⅗)/,
        four_fifths:   /(&#8536;|⅘)/,
        one_sixth:     /(&#8537;|⅙)/,
        five_sixths:   /(&#8538;|⅚)/,
        one_eighth:    /(&#8539;|⅛)/,
        three_eighths: /(&#8540;|⅜)/,
        five_eighths:  /(&#8541;|⅝)/,
        seven_eighths: /(&#8542;|⅞)/,
      }

      WHITESPACE = /\s+/

      class << self
        %w{
          abbreviation
          accented_html_entity
          apostrophe
          characters
          cleanup_characters
          cleanup_html_entities
          currencies
          currencies_simple
          currencies_complex
          html_entities
          html_tag
          smart_punctuation
          unreadable_control_characters
          vulgar_fractions
          whitespace
        }.each do |conversion_type|
          define_method conversion_type do
            const_get conversion_type.upcase
          end
        end
      end
    end
  end
end
