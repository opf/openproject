#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module OAuthClients
  class CreateContract < ::ModelContract
    include ActiveModel::Validations

    attribute :client_id, writable: true
    validates :client_id, presence: true, length: { maximum: 255 }

    attribute :client_secret, writable: true
    validates :client_secret, presence: true, length: { maximum: 255 }

    attribute :integration_type, writable: true
    validates :integration_type, presence: true

    attribute :integration_id, writable: true
    validates :integration_id, presence: true

    validate :validate_user_allowed

    private

    def validate_user_allowed
      unless user.admin? && user.active?
        errors.add :base, :error_unauthorized
      end
    end
  end
end
