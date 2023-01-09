#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'net/ldap'

class LdapAuthSource < AuthSource
  enum tls_mode: {
    plain_ldap: 0,
    simple_tls: 1,
    start_tls: 2
  }.freeze, _default: :start_tls
  validates :tls_mode, inclusion: { in: tls_modes.keys }

  validates_presence_of :host, :port, :attr_login
  validates_length_of :name, :host, maximum: 60, allow_nil: true
  validates_length_of :account, :account_password, :base_dn, maximum: 255, allow_nil: true
  validates_length_of :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :attr_admin, maximum: 30, allow_nil: true
  validates_numericality_of :port, only_integer: true

  validate :validate_filter_string
  validate :validate_tls_certificate_string, if: -> { tls_certificate_string.present? }

  after_initialize :set_default_port
  before_validation :strip_ldap_attributes

  def authenticate(login, password)
    return nil if login.blank? || password.blank?

    attrs = get_user_dn(login)

    if attrs && attrs[:dn] && authenticate_dn(attrs[:dn], password)
      Rails.logger.debug { "Authentication successful for '#{login}'" }
      attrs.except(:dn)
    end
  rescue Net::LDAP::Error => e
    raise AuthSource::Error, "LdapError: #{e.message}"
  end

  def find_user(login)
    return nil if login.blank?

    attrs = get_user_dn(login)

    if attrs && attrs[:dn]
      Rails.logger.debug { "Lookup successful for '#{login}'" }
      attrs.except(:dn)
    end
  rescue Net::LDAP::Error => e
    raise AuthSource::Error, "LdapError: #{e.message}"
  end

  # Open and return a system connection
  def with_connection
    yield initialize_ldap_con(account, account_password)
  end

  # test the connection to the LDAP
  def test_connection
    unless authenticate_dn(account, account_password)
      raise AuthSource::Error, I18n.t('auth_source.ldap_error', error_message: I18n.t('auth_source.ldap_auth_failed'))
    end
  rescue Net::LDAP::Error => e
    raise AuthSource::Error, I18n.t('auth_source.ldap_error', error_message: e.to_s)
  end

  def auth_method_name
    'LDAP'
  end

  def get_user_attributes_from_ldap_entry(entry)
    base_attributes = {
      dn: entry.dn,
      auth_source_id: id
    }

    base_attributes.merge mapped_attributes(entry)
  end

  def mapped_attributes(entry)
    %i[login firstname lastname mail admin].each_with_object({}) do |key, hash|
      ldap_attribute = send(:"attr_#{key}")
      next if ldap_attribute.blank?

      val = LdapAuthSource.get_attr(entry, ldap_attribute)
      val = !!ActiveRecord::Type::Boolean.new.cast(val) if key == :admin
      hash[key] = val
    end
  end

  # Return the attributes needed for the LDAP search.
  #
  # @param all_attributes [Boolean] Whether to return all user attributes
  #
  # By default, it will only include the user attributes if on-the-fly registration is enabled
  def search_attributes(all_attributes = onthefly_register?)
    if all_attributes
      ['dn', attr_login, attr_firstname, attr_lastname, attr_mail, attr_admin].compact
    else
      ['dn', attr_login]
    end
  end

  ##
  # Returns the filter object used for searching
  def default_filter
    object_filter = Net::LDAP::Filter.eq('objectClass', '*')
    parsed_filter_string || object_filter
  end

  ##
  # Returns the filter object to search for a login
  # adding the optional default filter
  def login_filter(login)
    Net::LDAP::Filter.eq(attr_login, login) & default_filter
  end

  def parsed_filter_string
    Net::LDAP::Filter.from_rfc2254(filter_string) if filter_string.present?
  end

  def ldap_connection_options
    {
      host:,
      port:,
      force_no_page: OpenProject::Configuration.ldap_force_no_page,
      encryption: ldap_encryption
    }
  end

  def read_ldap_certificates
    return if tls_certificate_string.blank?

    # Using load will allow multiple PEM certificates to be passed
    OpenSSL::X509::Certificate.load(tls_certificate_string)
  end

  private

  def strip_ldap_attributes
    %i[attr_login attr_firstname attr_lastname attr_mail attr_admin].each do |attr|
      write_attribute(attr, read_attribute(attr).strip) unless read_attribute(attr).nil?
    end
  end

  def initialize_ldap_con(ldap_user, ldap_password)
    unless plain_ldap? || verify_peer?
      Rails.logger.info { "SSL connection to LDAP host #{host} is set up to skip certificate verification." }
    end

    options = ldap_connection_options
    unless ldap_user.blank? && ldap_password.blank?
      options.merge!(auth: { method: :simple, username: ldap_user,
                             password: ldap_password })
    end
    Net::LDAP.new options
  end

  def ldap_encryption
    return nil if plain_ldap?

    {
      method: tls_mode.to_sym,
      tls_options:
    }
  end

  def cert_store
    @cert_store ||= OpenSSL::X509::Store.new.tap do |store|
      store.set_default_paths
      provided_certs = Array(read_ldap_certificates)
      provided_certs.each { |cert| store.add_cert cert }
    end
  end

  def tls_options
    {
      verify_mode: tls_verify_mode,
      cert_store:
    }.compact
  end

  def tls_verify_mode
    if verify_peer?
      OpenSSL::SSL::VERIFY_PEER
    else
      OpenSSL::SSL::VERIFY_NONE
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

    attrs = {}

    filter = login_filter(login)
    Rails.logger.debug do
      "LDAP initializing search (BASE=#{base_dn}), (FILTER=#{filter})"
    end

    ldap_con.search(base: base_dn,
                    filter: filter,
                    attributes: search_attributes) do |entry|
      attrs =
        if onthefly_register?
          get_user_attributes_from_ldap_entry(entry)
        else
          { dn: entry.dn }
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

  def validate_filter_string
    parsed_filter_string
  rescue Net::LDAP::FilterSyntaxInvalidError
    errors.add :filter_string, :invalid
  end

  def validate_tls_certificate_string
    read_ldap_certificates
  rescue OpenSSL::X509::CertificateError => e
    errors.add :tls_certificate_string, :invalid_certificate, additional_message: e.message
  end
end
