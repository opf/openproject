module CodeRay

# = WordList
# 
# <b>A Hash subclass designed for mapping word lists to token types.</b>
# 
# Copyright (c) 2006 by murphy (Kornelius Kalnbach) <murphy rubychan de>
#
# License:: LGPL / ask the author
# Version:: 1.1 (2006-Oct-19)
#
# A WordList is a Hash with some additional features.
# It is intended to be used for keyword recognition.
#
# WordList is highly optimized to be used in Scanners,
# typically to decide whether a given ident is a special token.
#
# For case insensitive words use CaseIgnoringWordList.
#
# Example:
#
#  # define word arrays
#  RESERVED_WORDS = %w[
#    asm break case continue default do else
#    ...
#  ]
#  
#  PREDEFINED_TYPES = %w[
#    int long short char void
#    ...
#  ]
#  
#  PREDEFINED_CONSTANTS = %w[
#    EOF NULL ...
#  ]
#  
#  # make a WordList
#  IDENT_KIND = WordList.new(:ident).
#    add(RESERVED_WORDS, :reserved).
#    add(PREDEFINED_TYPES, :pre_type).
#    add(PREDEFINED_CONSTANTS, :pre_constant)
#
#  ...
#
#  def scan_tokens tokens, options
#    ...
#    
#    elsif scan(/[A-Za-z_][A-Za-z_0-9]*/)
#      # use it
#      kind = IDENT_KIND[match]
#      ...
class WordList < Hash

  # Creates a new WordList with +default+ as default value.
  # 
  # You can activate +caching+ to store the results for every [] request.
  # 
  # With caching, methods like +include?+ or +delete+ may no longer behave
  # as you expect. Therefore, it is recommended to use the [] method only.
  def initialize default = false, caching = false, &block
    if block
      raise ArgumentError, 'Can\'t combine block with caching.' if caching
      super(&block)
    else
      if caching
        super() do |h, k|
          h[k] = h.fetch k, default
        end
      else
        super default
      end
    end
  end

  # Add words to the list and associate them with +kind+.
  # 
  # Returns +self+, so you can concat add calls.
  def add words, kind = true
    words.each do |word|
      self[word] = kind
    end
    self
  end

end


# A CaseIgnoringWordList is like a WordList, only that
# keys are compared case-insensitively.
# 
# Ignoring the text case is realized by sending the +downcase+ message to
# all keys.
# 
# Caching usually makes a CaseIgnoringWordList faster, but it has to be
# activated explicitely.
class CaseIgnoringWordList < WordList

  # Creates a new case-insensitive WordList with +default+ as default value.
  # 
  # You can activate caching to store the results for every [] request.
  # This speeds up subsequent lookups for the same word, but also
  # uses memory.
  def initialize default = false, caching = false
    if caching
      super(default, false) do |h, k|
        h[k] = h.fetch k.downcase, default
      end
    else
      super(default, false)
      extend Uncached
    end
  end
  
  module Uncached  # :nodoc:
    def [] key
      super(key.downcase)
    end
  end

  # Add +words+ to the list and associate them with +kind+.
  def add words, kind = true
    words.each do |word|
      self[word.downcase] = kind
    end
    self
  end

end

end

__END__
# check memory consumption
END {
  ObjectSpace.each_object(CodeRay::CaseIgnoringWordList) do |wl|
    p wl.inject(0) { |memo, key, value| memo + key.size + 24 }
  end
}