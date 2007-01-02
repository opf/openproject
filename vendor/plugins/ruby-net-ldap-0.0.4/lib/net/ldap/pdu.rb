# $Id: pdu.rb 126 2006-05-31 15:55:16Z blackhedd $
#
# LDAP PDU support classes
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


class LdapPduError < Exception; end


class LdapPdu

  BindResult = 1
  SearchReturnedData = 4
  SearchResult = 5
  ModifyResponse = 7
  AddResponse = 9
  DeleteResponse = 11
  ModifyRDNResponse = 13
  SearchResultReferral = 19

  attr_reader :msg_id, :app_tag
  attr_reader :search_dn, :search_attributes, :search_entry
  attr_reader :search_referrals

  #
  # initialize
  # An LDAP PDU always looks like a BerSequence with
  # at least two elements: an integer (message-id number), and
  # an application-specific sequence.
  # Some LDAPv3 packets also include an optional
  # third element, which is a sequence of "controls"
  # (See RFC 2251, section 4.1.12).
  # The application-specific tag in the sequence tells
  # us what kind of packet it is, and each kind has its
  # own format, defined in RFC-1777.
  # Observe that many clients (such as ldapsearch)
  # do not necessarily enforce the expected application
  # tags on received protocol packets. This implementation
  # does interpret the RFC strictly in this regard, and
  # it remains to be seen whether there are servers out
  # there that will not work well with our approach.
  #
  # Added a controls-processor to SearchResult.
  # Didn't add it everywhere because it just _feels_
  # like it will need to be refactored.
  #
  def initialize ber_object
    begin
      @msg_id = ber_object[0].to_i
      @app_tag = ber_object[1].ber_identifier - 0x60
    rescue
      # any error becomes a data-format error
      raise LdapPduError.new( "ldap-pdu format error" )
    end

    case @app_tag
    when BindResult
      parse_ldap_result ber_object[1]
    when SearchReturnedData
      parse_search_return ber_object[1]
    when SearchResultReferral
      parse_search_referral ber_object[1]
    when SearchResult
      parse_ldap_result ber_object[1]
      parse_controls(ber_object[2]) if ber_object[2]
    when ModifyResponse
      parse_ldap_result ber_object[1]
    when AddResponse
      parse_ldap_result ber_object[1]
    when DeleteResponse
      parse_ldap_result ber_object[1]
    when ModifyRDNResponse
      parse_ldap_result ber_object[1]
    else
      raise LdapPduError.new( "unknown pdu-type: #{@app_tag}" )
    end
  end

  #
  # result_code
  # This returns an LDAP result code taken from the PDU,
  # but it will be nil if there wasn't a result code.
  # That can easily happen depending on the type of packet.
  #
  def result_code code = :resultCode
    @ldap_result and @ldap_result[code]
  end

  # Return RFC-2251 Controls if any.
  # Messy. Does this functionality belong somewhere else?
  def result_controls
    @ldap_controls || []
  end


  #
  # parse_ldap_result
  #
  def parse_ldap_result sequence
    sequence.length >= 3 or raise LdapPduError
    @ldap_result = {:resultCode => sequence[0], :matchedDN => sequence[1], :errorMessage => sequence[2]}
  end
  private :parse_ldap_result

  #
  # parse_search_return
  # Definition from RFC 1777 (we're handling application-4 here)
  #
  # Search Response ::=
  #    CHOICE {
  #         entry          [APPLICATION 4] SEQUENCE {
  #                             objectName     LDAPDN,
  #                             attributes     SEQUENCE OF SEQUENCE {
  #                                                 AttributeType,
  #                                                 SET OF AttributeValue
  #                                            }
  #                        },
  #         resultCode     [APPLICATION 5] LDAPResult
  #     }
  #
  # We concoct a search response that is a hash of the returned attribute values.
  # NOW OBSERVE CAREFULLY: WE ARE DOWNCASING THE RETURNED ATTRIBUTE NAMES.
  # This is to make them more predictable for user programs, but it
  # may not be a good idea. Maybe this should be configurable.
  # ALTERNATE IMPLEMENTATION: In addition to @search_dn and @search_attributes,
  # we also return @search_entry, which is an LDAP::Entry object.
  # If that works out well, then we'll remove the first two.
  #
  # Provisionally removed obsolete search_attributes and search_dn, 04May06.
  #
  def parse_search_return sequence
    sequence.length >= 2 or raise LdapPduError
    @search_entry = LDAP::Entry.new( sequence[0] )
    #@search_dn = sequence[0]
    #@search_attributes = {}
    sequence[1].each {|seq|
      @search_entry[seq[0]] = seq[1]
      #@search_attributes[seq[0].downcase.intern] = seq[1]
    }
  end

  #
  # A search referral is a sequence of one or more LDAP URIs.
  # Any number of search-referral replies can be returned by the server, interspersed
  # with normal replies in any order.
  # Until I can think of a better way to do this, we'll return the referrals as an array.
  # It'll be up to higher-level handlers to expose something reasonable to the client.
  def parse_search_referral uris
    @search_referrals = uris
  end


  # Per RFC 2251, an LDAP "control" is a sequence of tuples, each consisting
  # of an OID, a boolean criticality flag defaulting FALSE, and an OPTIONAL
  # Octet String. If only two fields are given, the second one may be
  # either criticality or data, since criticality has a default value.
  # Someday we may want to come back here and add support for some of
  # more-widely used controls. RFC-2696 is a good example.
  #
  def parse_controls sequence
    @ldap_controls = sequence.map do |control|
      o = OpenStruct.new
      o.oid,o.criticality,o.value = control[0],control[1],control[2]
      if o.criticality and o.criticality.is_a?(String)
        o.value = o.criticality
        o.criticality = false
      end
      o
    end
  end
  private :parse_controls


end


end # module Net

