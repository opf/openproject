# $Id: psw.rb 73 2006-04-24 21:59:35Z blackhedd $
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


class Password
  class << self

  # Generate a password-hash suitable for inclusion in an LDAP attribute.
  # Pass a hash type (currently supported: :md5 and :sha) and a plaintext
  # password. This function will return a hashed representation.
  # STUB: This is here to fulfill the requirements of an RFC, which one?
  # TODO, gotta do salted-sha and (maybe) salted-md5.
  # Should we provide sha1 as a synonym for sha1? I vote no because then
  # should you also provide ssha1 for symmetry?
  def generate( type, str )
    case type
    when :md5
      require 'md5'
      "{MD5}#{ [MD5.new( str.to_s ).digest].pack("m").chomp }"
    when :sha
      require 'sha1'
      "{SHA}#{ [SHA1.new( str.to_s ).digest].pack("m").chomp }"
    # when ssha
    else
      raise Net::LDAP::LdapError.new( "unsupported password-hash type (#{type})" )
    end
  end

  end
end


end # class LDAP
end # module Net


