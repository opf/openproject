# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'net/ldap'
require 'iconv'

class AuthSourceLdap < AuthSource 
  validates_presence_of :host, :port, :attr_login

  def after_initialize
    self.port = 389 if self.port == 0
  end
  
  def authenticate(login, password)
    attrs = []
    # get user's DN
    ldap_con = initialize_ldap_con(self.account, self.account_password)
    login_filter = Net::LDAP::Filter.eq( self.attr_login, login ) 
    object_filter = Net::LDAP::Filter.eq( "objectClass", "*" ) 
    dn = String.new
    ldap_con.search( :base => self.base_dn, 
                     :filter => object_filter & login_filter, 
                     :attributes=> ['dn', self.attr_firstname, self.attr_lastname, self.attr_mail]) do |entry|
      dn = entry.dn
      attrs = [:firstname => AuthSourceLdap.get_attr(entry, self.attr_firstname),
               :lastname => AuthSourceLdap.get_attr(entry, self.attr_lastname),
               :mail => AuthSourceLdap.get_attr(entry, self.attr_mail),
               :auth_source_id => self.id ]
    end
    return nil if dn.empty?
    logger.debug "DN found for #{login}: #{dn}" if logger && logger.debug?
    # authenticate user
    ldap_con = initialize_ldap_con(dn, password)
    return nil unless ldap_con.bind
    # return user's attributes
    logger.debug "Authentication successful for '#{login}'" if logger && logger.debug?
    attrs    
  rescue  Net::LDAP::LdapError => text
    raise "LdapError: " + text
  end

  # test the connection to the LDAP
  def test_connection
    ldap_con = initialize_ldap_con(self.account, self.account_password)
    ldap_con.open { }
  rescue  Net::LDAP::LdapError => text
    raise "LdapError: " + text
  end
 
  def auth_method_name
    "LDAP"
  end
  
private
  def initialize_ldap_con(ldap_user, ldap_password)
    Net::LDAP.new( {:host => self.host, 
                    :port => self.port, 
                    :auth => { :method => :simple, :username => Iconv.new('iso-8859-15', 'utf-8').iconv(ldap_user), :password => Iconv.new('iso-8859-15', 'utf-8').iconv(ldap_password) }} 
    ) 
  end
  
  def self.get_attr(entry, attr_name)
    entry[attr_name].is_a?(Array) ? entry[attr_name].first : entry[attr_name]
  end
end
