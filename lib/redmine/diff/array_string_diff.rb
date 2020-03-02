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

class Redmine::Diff::ArrayStringDiff
  VERSION = 0.3

  def self.lcs(a, b)
    astart = 0
    bstart = 0
    afinish = a.length - 1
    bfinish = b.length - 1
    mvector = []

    # First we prune off any common elements at the beginning
    while astart <= afinish && bstart <= afinish && a[astart] == b[bstart]
      mvector[astart] = bstart
      astart += 1
      bstart += 1
    end

    # now the end
    while astart <= afinish && bstart <= bfinish && a[afinish] == b[bfinish]
      mvector[afinish] = bfinish
      afinish -= 1
      bfinish -= 1
    end

    bmatches = b.reverse_hash(bstart..bfinish)
    thresh = []
    links = []

    (astart..afinish).each do |aindex|
      aelem = a[aindex]
      next unless bmatches.has_key? aelem
      k = nil
      bmatches[aelem].reverse_each { |bindex|
        if k && (thresh[k] > bindex) && (thresh[k - 1] < bindex)
          thresh[k] = bindex
        else
          k = thresh.replacenextlarger(bindex, k)
        end
        links[k] = [(k == 0) ? nil : links[k - 1], aindex, bindex] if k
      }
    end

    if !thresh.empty?
      link = links[thresh.length - 1]
      while link
        mvector[link[1]] = link[2]
        link = link[0]
      end
    end

    mvector
  end

  def makediff(a, b)
    mvector = self.class.lcs(a, b)
    ai = bi = 0
    while ai < mvector.length
      bline = mvector[ai]
      if bline
        while bi < bline
          discardb(bi, b[bi])
          bi += 1
        end
        match(ai, bi)
        bi += 1
      else
        discarda(ai, a[ai])
      end
      ai += 1
    end
    while ai < a.length
      discarda(ai, a[ai])
      ai += 1
    end
    while bi < b.length
      discardb(bi, b[bi])
      bi += 1
    end
    match(ai, bi)
    1
  end

  def compactdiffs
    diffs = []
    @diffs.each do |df|
      i = 0
      curdiff = []
      while i < df.length
        whot = df[i][0]
        s = @isstring ? df[i][2].chr : [df[i][2]]
        p = df[i][1]
        last = df[i][1]
        i += 1
        while df[i] && df[i][0] == whot && df[i][1] == last + 1
          s << df[i][2]
          last  = df[i][1]
          i += 1
        end
        curdiff.push [whot, p, s]
      end
      diffs.push curdiff
    end
    diffs
  end

  attr_reader :diffs, :difftype

  def initialize(diffs_or_a, b = nil, isstring = nil)
    if b.nil?
      @diffs = diffs_or_a
      @isstring = isstring
    else
      @diffs = []
      @curdiffs = []
      makediff(diffs_or_a, b)
      @difftype = diffs_or_a.class
    end
  end

  def match(_ai, _bi)
    @diffs.push @curdiffs unless @curdiffs.empty?
    @curdiffs = []
  end

  def discarda(i, elem)
    @curdiffs.push ['-', i, elem]
  end

  def discardb(i, elem)
    @curdiffs.push ['+', i, elem]
  end

  def compact
    Diff.new(compactdiffs)
  end

  def compact!
    @diffs = compactdiffs
  end

  def inspect
    @diffs.inspect
  end
end
