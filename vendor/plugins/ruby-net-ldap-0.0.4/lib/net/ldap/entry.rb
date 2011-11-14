#-- encoding: UTF-8
# $Id: entry.rb 123 2006-05-18 03:52:38Z blackhedd $
#
# LDAP Entry (search-result) support classes
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




module Net
class LDAP


  # Objects of this class represent individual entries in an LDAP
  # directory. User code generally does not instantiate this class.
  # Net::LDAP#search provides objects of this class to user code,
  # either as block parameters or as return values.
  #
  # In LDAP-land, an "entry" is a collection of attributes that are
  # uniquely and globally identified by a DN ("Distinguished Name").
  # Attributes are identified by short, descriptive words or phrases.
  # Although a directory is
  # free to implement any attribute name, most of them follow rigorous
  # standards so that the range of commonly-encountered attribute
  # names is not large.
  #
  # An attribute name is case-insensitive. Most directories also
  # restrict the range of characters allowed in attribute names.
  # To simplify handling attribute names, Net::LDAP::Entry
  # internally converts them to a standard format. Therefore, the
  # methods which take attribute names can take Strings or Symbols,
  # and work correctly regardless of case or capitalization.
  #
  # An attribute consists of zero or more data items called
  # <i>values.</i> An entry is the combination of a unique DN, a set of attribute
  # names, and a (possibly-empty) array of values for each attribute.
  #
  # Class Net::LDAP::Entry provides convenience methods for dealing
  # with LDAP entries.
  # In addition to the methods documented below, you may access individual
  # attributes of an entry simply by giving the attribute name as
  # the name of a method call. For example:
  #  ldap.search( ... ) do |entry|
  #    puts "Common name: #{entry.cn}"
  #    puts "Email addresses:"
  #      entry.mail.each {|ma| puts ma}
  #  end
  # If you use this technique to access an attribute that is not present
  # in a particular Entry object, a NoMethodError exception will be raised.
  #
  #--
  # Ugly problem to fix someday: We key off the internal hash with
  # a canonical form of the attribute name: convert to a string,
  # downcase, then take the symbol. Unfortunately we do this in
  # at least three places. Should do it in ONE place.
  class Entry

    # This constructor is not generally called by user code.
    def initialize dn = nil # :nodoc:
      @myhash = Hash.new {|k,v| k[v] = [] }
      @myhash[:dn] = [dn]
    end


    def []= name, value # :nodoc:
      sym = name.to_s.downcase.intern
      @myhash[sym] = value
    end


    #--
    # We have to deal with this one as we do with []=
    # because this one and not the other one gets called
    # in formulations like entry["CN"] << cn.
    #
    def [] name # :nodoc:
      name = name.to_s.downcase.intern unless name.is_a?(Symbol)
      @myhash[name]
    end

    # Returns the dn of the Entry as a String.
    def dn
      self[:dn][0]
    end

    # Returns an array of the attribute names present in the Entry.
    def attribute_names
      @myhash.keys
    end

    # Accesses each of the attributes present in the Entry.
    # Calls a user-supplied block with each attribute in turn,
    # passing two arguments to the block: a Symbol giving
    # the name of the attribute, and a (possibly empty)
    # Array of data values.
    #
    def each
      if block_given?
        attribute_names.each {|a|
          attr_name,values = a,self[a]
          yield attr_name, values
        }
      end
    end

    alias_method :each_attribute, :each


    #--
    # Convenience method to convert unknown method names
    # to attribute references. Of course the method name
    # comes to us as a symbol, so let's save a little time
    # and not bother with the to_s.downcase two-step.
    # Of course that means that a method name like mAIL
    # won't work, but we shouldn't be encouraging that
    # kind of bad behavior in the first place.
    # Maybe we should thow something if the caller sends
    # arguments or a block...
    #
    def method_missing *args, &block # :nodoc:
      s = args[0].to_s.downcase.intern
      if attribute_names.include?(s)
        self[s]
      elsif s.to_s[-1] == 61 and s.to_s.length > 1
        value = args[1] or raise RuntimeError.new( "unable to set value" )
        value = [value] unless value.is_a?(Array)
        name = s.to_s[0..-2].intern
        self[name] = value
      else
        raise NoMethodError.new( "undefined method '#{s}'" )
      end
    end

    def write
    end

  end # class Entry


end # class LDAP
end # module Net


