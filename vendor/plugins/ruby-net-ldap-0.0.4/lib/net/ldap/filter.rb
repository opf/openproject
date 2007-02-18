# $Id: filter.rb 151 2006-08-15 08:34:53Z blackhedd $
#
#
#----------------------------------------------------------------------------
#
# Copyright (C) 2006 by Francis Cianfrocca. All Rights Reserved.
#
# Gmail: garbagecat10
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#---------------------------------------------------------------------------
#
#


module Net
class LDAP


# Class Net::LDAP::Filter is used to constrain
# LDAP searches. An object of this class is
# passed to Net::LDAP#search in the parameter :filter.
#
# Net::LDAP::Filter supports the complete set of search filters
# available in LDAP, including conjunction, disjunction and negation
# (AND, OR, and NOT). This class supplants the (infamous) RFC-2254
# standard notation for specifying LDAP search filters.
#
# Here's how to code the familiar "objectclass is present" filter:
#  f = Net::LDAP::Filter.pres( "objectclass" )
# The object returned by this code can be passed directly to
# the <tt>:filter</tt> parameter of Net::LDAP#search.
#
# See the individual class and instance methods below for more examples.
#
class Filter

  def initialize op, a, b
    @op = op
    @left = a
    @right = b
  end

  # #eq creates a filter object indicating that the value of
  # a paticular attribute must be either <i>present</i> or must
  # match a particular string.
  #
  # To specify that an attribute is "present" means that only
  # directory entries which contain a value for the particular
  # attribute will be selected by the filter. This is useful
  # in case of optional attributes such as <tt>mail.</tt>
  # Presence is indicated by giving the value "*" in the second
  # parameter to #eq. This example selects only entries that have
  # one or more values for <tt>sAMAccountName:</tt>
  #  f = Net::LDAP::Filter.eq( "sAMAccountName", "*" )
  #
  # To match a particular range of values, pass a string as the
  # second parameter to #eq. The string may contain one or more
  # "*" characters as wildcards: these match zero or more occurrences
  # of any character. Full regular-expressions are <i>not</i> supported
  # due to limitations in the underlying LDAP protocol.
  # This example selects any entry with a <tt>mail</tt> value containing
  # the substring "anderson":
  #  f = Net::LDAP::Filter.eq( "mail", "*anderson*" )
  #--
  # Removed gt and lt. They ain't in the standard!
  #
  def Filter::eq attribute, value; Filter.new :eq, attribute, value; end
  def Filter::ne attribute, value; Filter.new :ne, attribute, value; end
  #def Filter::gt attribute, value; Filter.new :gt, attribute, value; end
  #def Filter::lt attribute, value; Filter.new :lt, attribute, value; end
  def Filter::ge attribute, value; Filter.new :ge, attribute, value; end
  def Filter::le attribute, value; Filter.new :le, attribute, value; end

  # #pres( attribute ) is a synonym for #eq( attribute, "*" )
  #
  def Filter::pres attribute; Filter.eq attribute, "*"; end

  # operator & ("AND") is used to conjoin two or more filters.
  # This expression will select only entries that have an <tt>objectclass</tt>
  # attribute AND have a <tt>mail</tt> attribute that begins with "George":
  #  f = Net::LDAP::Filter.pres( "objectclass" ) & Net::LDAP::Filter.eq( "mail", "George*" )
  #
  def & filter; Filter.new :and, self, filter; end

  # operator | ("OR") is used to disjoin two or more filters.
  # This expression will select entries that have either an <tt>objectclass</tt>
  # attribute OR a <tt>mail</tt> attribute that begins with "George":
  #  f = Net::LDAP::Filter.pres( "objectclass" ) | Net::LDAP::Filter.eq( "mail", "George*" )
  #
  def | filter; Filter.new :or, self, filter; end


  #
  # operator ~ ("NOT") is used to negate a filter.
  # This expression will select only entries that <i>do not</i> have an <tt>objectclass</tt>
  # attribute:
  #  f = ~ Net::LDAP::Filter.pres( "objectclass" )
  #
  #--
  # This operator can't be !, evidently. Try it.
  # Removed GT and LT. They're not in the RFC.
  def ~@; Filter.new :not, self, nil; end


  def to_s
    case @op
    when :ne
      "(!(#{@left}=#{@right}))"
    when :eq
      "(#{@left}=#{@right})"
    #when :gt
     # "#{@left}>#{@right}"
    #when :lt
     # "#{@left}<#{@right}"
    when :ge
      "#{@left}>=#{@right}"
    when :le
      "#{@left}<=#{@right}"
    when :and
      "(&(#{@left})(#{@right}))"
    when :or
      "(|(#{@left})(#{@right}))"
    when :not
      "(!(#{@left}))"
    else
      raise "invalid or unsupported operator in LDAP Filter"
    end
  end


  #--
  # to_ber
  # Filter ::=
  #     CHOICE {
  #         and            [0] SET OF Filter,
  #         or             [1] SET OF Filter,
  #         not            [2] Filter,
  #         equalityMatch  [3] AttributeValueAssertion,
  #         substrings     [4] SubstringFilter,
  #         greaterOrEqual [5] AttributeValueAssertion,
  #         lessOrEqual    [6] AttributeValueAssertion,
  #         present        [7] AttributeType,
  #         approxMatch    [8] AttributeValueAssertion
  #     }
  #
  # SubstringFilter
  #     SEQUENCE {
  #         type               AttributeType,
  #         SEQUENCE OF CHOICE {
  #             initial        [0] LDAPString,
  #             any            [1] LDAPString,
  #             final          [2] LDAPString
  #         }
  #     }
  #
  # Parsing substrings is a little tricky.
  # We use the split method to break a string into substrings
  # delimited by the * (star) character. But we also need
  # to know whether there is a star at the head and tail
  # of the string. A Ruby particularity comes into play here:
  # if you split on * and the first character of the string is
  # a star, then split will return an array whose first element
  # is an _empty_ string. But if the _last_ character of the
  # string is star, then split will return an array that does
  # _not_ add an empty string at the end. So we have to deal
  # with all that specifically.
  #
  def to_ber
    case @op
    when :eq
      if @right == "*"          # present
        @left.to_s.to_ber_contextspecific 7
      elsif @right =~ /[\*]/    #substring
        ary = @right.split( /[\*]+/ )
        final_star = @right =~ /[\*]$/
        initial_star = ary.first == "" and ary.shift

        seq = []
        unless initial_star
          seq << ary.shift.to_ber_contextspecific(0)
        end
        n_any_strings = ary.length - (final_star ? 0 : 1)
        #p n_any_strings
        n_any_strings.times {
          seq << ary.shift.to_ber_contextspecific(1)
        }
        unless final_star
          seq << ary.shift.to_ber_contextspecific(2)
        end
        [@left.to_s.to_ber, seq.to_ber].to_ber_contextspecific 4
      else                      #equality
        [@left.to_s.to_ber, @right.to_ber].to_ber_contextspecific 3
      end
    when :ge
      [@left.to_s.to_ber, @right.to_ber].to_ber_contextspecific 5
    when :le
      [@left.to_s.to_ber, @right.to_ber].to_ber_contextspecific 6
    when :and
      ary = [@left.coalesce(:and), @right.coalesce(:and)].flatten
      ary.map {|a| a.to_ber}.to_ber_contextspecific( 0 )
    when :or
      ary = [@left.coalesce(:or), @right.coalesce(:or)].flatten
      ary.map {|a| a.to_ber}.to_ber_contextspecific( 1 )
    when :not
        [@left.to_ber].to_ber_contextspecific 2
    else
      # ERROR, we'll return objectclass=* to keep things from blowing up,
      # but that ain't a good answer and we need to kick out an error of some kind.
      raise "unimplemented search filter"
    end
  end

  #--
  # coalesce
  # This is a private helper method for dealing with chains of ANDs and ORs
  # that are longer than two. If BOTH of our branches are of the specified
  # type of joining operator, then return both of them as an array (calling
  # coalesce recursively). If they're not, then return an array consisting
  # only of self.
  #
  def coalesce operator
    if @op == operator
      [@left.coalesce( operator ), @right.coalesce( operator )]
    else
      [self]
    end
  end



  #--
  # We get a Ruby object which comes from parsing an RFC-1777 "Filter"
  # object. Convert it to a Net::LDAP::Filter.
  # TODO, we're hardcoding the RFC-1777 BER-encodings of the various
  # filter types. Could pull them out into a constant.
  #
  def Filter::parse_ldap_filter obj
    case obj.ber_identifier
    when 0x87         # present. context-specific primitive 7.
      Filter.eq( obj.to_s, "*" )
    when 0xa3         # equalityMatch. context-specific constructed 3.
      Filter.eq( obj[0], obj[1] )
    else
      raise LdapError.new( "unknown ldap search-filter type: #{obj.ber_identifier}" )
    end
  end


  #--
  # We got a hash of attribute values.
  # Do we match the attributes?
  # Return T/F, and call match recursively as necessary.
  def match entry
    case @op
    when :eq
      if @right == "*"
        l = entry[@left] and l.length > 0
      else
        l = entry[@left] and l = l.to_a and l.index(@right)
      end
    else
      raise LdapError.new( "unknown filter type in match: #{@op}" )
    end
  end

  # Converts an LDAP filter-string (in the prefix syntax specified in RFC-2254)
  # to a Net::LDAP::Filter.
  def self.construct ldap_filter_string
    FilterParser.new(ldap_filter_string).filter
  end

  # Synonym for #construct.
  # to a Net::LDAP::Filter.
  def self.from_rfc2254 ldap_filter_string
    construct ldap_filter_string
  end

end # class Net::LDAP::Filter



class FilterParser #:nodoc:

  attr_reader :filter

  def initialize str
    require 'strscan'
    @filter = parse( StringScanner.new( str )) or raise Net::LDAP::LdapError.new( "invalid filter syntax" )
  end

  def parse scanner
    parse_filter_branch(scanner) or parse_paren_expression(scanner)
  end

  def parse_paren_expression scanner
    if scanner.scan(/\s*\(\s*/)
      b = if scanner.scan(/\s*\&\s*/)
        a = nil
        branches = []
        while br = parse_paren_expression(scanner)
          branches << br
        end
        if branches.length >= 2
          a = branches.shift
          while branches.length > 0
            a = a & branches.shift
          end
          a
        end
      elsif scanner.scan(/\s*\|\s*/)
        # TODO: DRY!
        a = nil
        branches = []
        while br = parse_paren_expression(scanner)
          branches << br
        end
        if branches.length >= 2
          a = branches.shift
          while branches.length > 0
            a = a | branches.shift
          end
          a
        end
      elsif scanner.scan(/\s*\!\s*/)
        br = parse_paren_expression(scanner)
        if br
          ~ br
        end
      else
        parse_filter_branch( scanner )
      end

      if b and scanner.scan( /\s*\)\s*/ )
        b
      end
    end
  end

  # Added a greatly-augmented filter contributed by Andre Nathan
  # for detecting special characters in values. (15Aug06)
  def parse_filter_branch scanner
    scanner.scan(/\s*/)
    if token = scanner.scan( /[\w\-_]+/ )
      scanner.scan(/\s*/)
      if op = scanner.scan( /\=|\<\=|\<|\>\=|\>|\!\=/ )
        scanner.scan(/\s*/)
        #if value = scanner.scan( /[\w\*\.]+/ ) (ORG)
        if value = scanner.scan( /[\w\*\.\+\-@=#\$%&!]+/ )
          case op
          when "="
            Filter.eq( token, value )
          when "!="
            Filter.ne( token, value )
          when "<"
            Filter.lt( token, value )
          when "<="
            Filter.le( token, value )
          when ">"
            Filter.gt( token, value )
          when ">="
            Filter.ge( token, value )
          end
        end
      end
    end
  end

end # class Net::LDAP::FilterParser

end # class Net::LDAP
end # module Net


