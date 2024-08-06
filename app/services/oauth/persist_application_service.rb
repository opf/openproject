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

module OAuth
  class PersistApplicationService
    include Contracted

    attr_reader :application, :current_user

    def initialize(model, user:)
      @application = model
      @current_user = user

      self.contract_class = OAuth::ApplicationContract
    end

    def call(attributes)
      set_defaults
      application.attributes = attributes
      set_secret_and_id

      result, errors = validate_and_save(application, current_user)
      ServiceResult.new success: result, errors:, result: application
    end

    def set_defaults
      return if application.owner_id

      application.owner = current_user
      application.owner_type = "User"
    end

    def set_secret_and_id
      application.extend(OpenProject::ChangedBySystem)
      application.change_by_system do
        application.renew_secret if application.secret.blank?
        application.uid = Doorkeeper::OAuth::Helpers::UniqueToken.generate if application.uid.blank?
      end
    end
  end
end
