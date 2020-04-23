#   = Diff
#   (({diff.rb})) - computes the differences between two arrays or
#   strings. Copyright (C) 2001 Lars Christensen
#
#   == Synopsis
#
#       diff = Diff.new(a, b)
#       b = a.patch(diff)
#
#   == Class Diff
#   === Class Methods
#   --- Diff.new(a, b)
#   --- a.diff(b)
#         Creates a Diff object which represent the differences between
#         ((|a|)) and ((|b|)). ((|a|)) and ((|b|)) can be either be arrays
#         of any objects, strings, or object of any class that include
#         module ((|Diffable|))
#
#   == Module Diffable
#   The module ((|Diffable|)) is intended to be included in any class for
#   which differences are to be computed. Diffable is included into String
#   and Array when (({diff.rb})) is (({require}))'d.
#
#   Classes including Diffable should implement (({[]})) to get element at
#   integer indices, (({<<})) to append elements to the object and
#   (({ClassName#new})) should accept 0 arguments to create a new empty
#   object.
#
#   === Instance Methods
#   --- Diffable#patch(diff)
#         Applies the differences from ((|diff|)) to the object ((|obj|))
#         and return the result. ((|obj|)) is not changed. ((|obj|)) and
#         can be either an array or a string, but must match the object
#         from which the ((|diff|)) was created.

module Redmine::Diff::Diffable
  def diff(b)
    Redmine::Diff::ArrayStringDiff.new(self, b)
  end

  # Create a hash that maps elements of the array to arrays of indices
  # where the elements are found.

  def reverse_hash(range = (0...length))
    revmap = {}
    range.each do |i|
      elem = self[i]
      if revmap.has_key? elem
        revmap[elem].push i
      else
        revmap[elem] = [i]
      end
    end
    revmap
  end

  def replacenextlarger(value, high = nil)
    high ||= length
    if self.empty? || value > self[-1]
      push value
      return high
    end
    # binary search for replacement point
    low = 0
    while low < high
      index = (high + low) / 2
      found = self[index]
      return nil if value == found
      if value > found
        low = index + 1
      else
        high = index
      end
    end

    self[low] = value
    # $stderr << "replace #{value} : 0/#{low}/#{init_high} (#{steps} steps) (#{init_high-low} off )\n"
    # $stderr.puts self.inspect
    # gets
    # p length - low
    low
  end

  def patch(diff)
    newary = nil
    if diff.difftype == String
      newary = diff.difftype.new('')
    else
      newary = diff.difftype.new
    end
    ai = 0
    bi = 0
    diff.diffs.each do |d|
      d.each { |mod|
        case mod[0]
        when '-'
          while ai < mod[1]
            newary << self[ai]
            ai += 1
            bi += 1
          end
          ai += 1
        when '+'
          while bi < mod[1]
            newary << self[ai]
            ai += 1
            bi += 1
          end
          newary << mod[2]
          bi += 1
        else
          raise 'Unknown diff action'
        end
      }
    end
    while ai < length
      newary << self[ai]
      ai += 1
      bi += 1
    end
    newary
  end
end
