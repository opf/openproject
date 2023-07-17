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
class NextcloudApplicationCredentialsValidator
  attr_reader :contract, :uri

  def initialize(contract)
    @contract = contract
    @uri = URI(contract.host).normalize
  end

  def call
    return unless contract.model.password_changed?

    case make_http_head_request_from(build_http_head_request)
    when Net::HTTPSuccess
      true
    when Net::HTTPUnauthorized
      contract.errors.add(:password, :invalid_password)
    else
      contract.errors.add(:password, :unknown_error)
    end
  end

  private

  def build_http_head_request
    request = Net::HTTP::Head.new Storages::Peripherals::StorageInteraction::Nextcloud::Util
      .join_uri_path(uri, "remote.php/dav")
    request.initialize_http_header Storages::Peripherals::StorageInteraction::Nextcloud::Util
      .basic_auth_header(contract.username, contract.password)
    request
  end

  def make_http_head_request_from(request)
    Storages::Peripherals::StorageInteraction::Nextcloud::Util
      .http(uri)
      .request(request)
  end
end
