# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      module Charsets
        autoload :EXPERT,           'ttfunk/table/cff/charsets/expert'
        autoload :EXPERT_SUBSET,    'ttfunk/table/cff/charsets/expert_subset'
        autoload :ISO_ADOBE,        'ttfunk/table/cff/charsets/iso_adobe'
        autoload :STANDARD_STRINGS, 'ttfunk/table/cff/charsets/standard_strings'
      end
    end
  end
end
