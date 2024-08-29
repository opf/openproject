#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

# Please see https://w3c.github.io/webappsec-secure-contexts/
# for a definition of "secure contexts".
# Basically, a host has to have either a HTTPS scheme or be
# localhost to provide a secure context.
class SecureContextUriValidator < ActiveModel::EachValidator
  def validate_each(contract, attribute, value)
    begin
      uri = URI.parse(value)
    rescue StandardError
      contract.errors.add(attribute, :invalid_url)
      return
    end

    # The URI could be parsable but not contain a host name
    if uri.host.blank?
      contract.errors.add(attribute, :invalid_url)
      return
    end

    unless self.class.secure_context_uri?(uri)
      contract.errors.add(attribute, :url_not_secure_context)
    end
  end

  def self.secure_context_uri?(uri)
    return true if uri.scheme == "https" # https is always safe
    return true if uri.host == "localhost" # Simple localhost
    return true if /\.localhost\.?$/.match?(uri.host) # i.e. 'foo.localhost' or 'foo.localhost.'

    # Check for loopback interface. The constructor can throw an exception for non IP addresses.
    # Those are invalid. And if the host is an IP address then we can check if it is loopback.
    begin
      return true if IPAddr.new(uri.host).loopback?
    rescue StandardError
      return false
    end

    # uri.host is an IP but not a loopback
    false
  end
end
