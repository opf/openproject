#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
class EnterpriseToken < ApplicationRecord
  class << self
    def current
      RequestStore.fetch(:current_ee_token) do
        set_current_token
      end
    end

    def table_exists?
      connection.data_source_exists? self.table_name
    end

    def allows_to?(action)
      Authorization::EnterpriseService.new(current).call(action).result
    end

    def show_banners?
      OpenProject::Configuration.ee_manager_visible? && (!current || current.expired?)
    end

    def set_current_token
      token = EnterpriseToken.order(Arel.sql('created_at DESC')).first

      if token&.token_object
        token
      end
    end
  end

  validates_presence_of :encoded_token
  validate :valid_token_object
  validate :valid_domain

  before_save :unset_current_token
  before_destroy :unset_current_token

  delegate :will_expire?,
           :subscriber,
           :mail,
           :company,
           :domain,
           :issued_at,
           :starts_at,
           :expires_at,
           :restrictions,
           to: :token_object

  def token_object
    load_token! unless defined?(@token_object)
    @token_object
  end

  def allows_to?(action)
    Authorization::EnterpriseService.new(self).call(action).result
  end

  def unset_current_token
    # Clear current cache
    RequestStore.delete :current_ee_token
  end

  def expired?
    token_object.expired? || invalid_domain?
  end

  ##
  # The domain is only validated for tokens from version 2.0 onwards.
  def invalid_domain?
    return false unless token_object&.validate_domain?

    token_object.domain != Setting.host_name
  end

  private

  def load_token!
    @token_object = OpenProject::Token.import(encoded_token)
  rescue OpenProject::Token::ImportError => error
    Rails.logger.error "Failed to load EE token: #{error}"
    nil
  end

  def valid_token_object
    errors.add(:encoded_token, :unreadable) unless load_token!
  end

  def valid_domain
    errors.add :domain, :invalid if invalid_domain?
  end
end
