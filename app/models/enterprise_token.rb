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
class EnterpriseToken < ActiveRecord::Base
  class << self
    def current
      RequestStore.fetch(:current_ee_token) do
        set_current_token
      end
    end

    def allows_to?(action)
      Authorization::EnterpriseService.new(current).call(action).result
    end

    def show_banners?
      OpenProject::Configuration.ee_manager_visible? && (!current || current.expired?)
    end

    def set_current_token
      token = EnterpriseToken.order('created_at DESC').first

      if token && token.token_object
        token
      end
    end
  end

  validates_presence_of :encoded_token
  validate :valid_token_object

  before_save :unset_current_token
  before_destroy :unset_current_token

  delegate :will_expire?,
           :expired?,
           :subscriber,
           :mail,
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
end
