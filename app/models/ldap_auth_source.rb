#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'net/ldap'

class LdapAuthSource < AuthSource
  validates_presence_of :host, :port, :attr_login
  validates_length_of :name, :host, maximum: 60, allow_nil: true
  validates_length_of :account, :account_password, :base_dn, maximum: 255, allow_nil: true
  validates_length_of :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :attr_admin, maximum: 30, allow_nil: true
  validates_numericality_of :port, only_integer: true

  before_validation :strip_ldap_attributes
  after_initialize :set_default_port

  def authenticate(login, password)
    return nil if login.blank? || password.blank?
    attrs = get_user_dn(login)

    if attrs && attrs[:dn] && authenticate_dn(attrs[:dn], password)
      Rails.logger.debug { "Authentication successful for '#{login}'" }
      return attrs.except(:dn)
    end
  rescue  Net::LDAP::LdapError => error
    raise 'LdapError: ' + error.message
  end

  # test the connection to the LDAP
  def test_connection
    unless authenticate_dn(account, account_password)
      raise I18n.t('auth_source.ldap_error', error_message: I18n.t('auth_source.ldap_auth_failed'))
    end
  rescue  Net::LDAP::LdapError => text
    raise I18n.t('auth_source.ldap_error', error_message: text.to_s)
  end

  def auth_method_name
    'LDAP'
  end

  private

  def strip_ldap_attributes
    [:attr_login, :attr_firstname, :attr_lastname, :attr_mail, :attr_admin].each do |attr|
      write_attribute(attr, read_attribute(attr).strip) unless read_attribute(attr).nil?
    end
  end

  def initialize_ldap_con(ldap_user, ldap_password)
    options = { host: host,
                port: port,
                force_no_page: true,
                encryption: (tls ? :simple_tls : nil)
              }
    options.merge!(auth: { method: :simple, username: ldap_user, password: ldap_password }) unless ldap_user.blank? && ldap_password.blank?
    Net::LDAP.new options
  end

  def get_user_attributes_from_ldap_entry(entry)
    {
      dn: entry.dn,
      firstname: LdapAuthSource.get_attr(entry, attr_firstname),
      lastname: LdapAuthSource.get_attr(entry, attr_lastname),
      mail: LdapAuthSource.get_attr(entry, attr_mail),
      admin: !!LdapAuthSource.get_attr(entry, attr_admin),
      auth_source_id: id
    }
  end

  # Return the attributes needed for the LDAP search.  It will only
  # include the user attributes if on-the-fly registration is enabled
  def search_attributes
    if onthefly_register?
      ['dn', attr_firstname, attr_lastname, attr_mail, attr_admin]
    else
      ['dn']
    end
  end

  # Check if a DN (user record) authenticates with the password
  def authenticate_dn(dn, password)
    if dn.present? && password.present?
      initialize_ldap_con(dn, password).bind
    end
  end

  # Get the user's dn and any attributes for them, given their login
  def get_user_dn(login)
    ldap_con = initialize_ldap_con(account, account_password)
    login_filter = Net::LDAP::Filter.eq(attr_login, login)
    object_filter = Net::LDAP::Filter.eq('objectClass', '*')
    attrs = {}

    Rails.logger.debug {
      "LDAP initializing search (BASE=#{base_dn}), (FILTER=#{(object_filter & login_filter).to_s})"
    }
    ldap_con.search(base: base_dn,
                    filter: object_filter & login_filter,
                    attributes: search_attributes) do |entry|
      if onthefly_register?
        attrs = get_user_attributes_from_ldap_entry(entry)
      else
        attrs = { dn: entry.dn }
      end

      Rails.logger.debug { "DN found for #{login}: #{attrs[:dn]}" }
    end

    attrs
  end

  def self.get_attr(entry, attr_name)
    if !attr_name.blank?
      entry[attr_name].is_a?(Array) ? entry[attr_name].first : entry[attr_name]
    end
  end

  def set_default_port
    self.port = 389 if port.to_i == 0
  end
end
