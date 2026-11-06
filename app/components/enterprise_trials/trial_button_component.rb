# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module EnterpriseTrials
  class TrialButtonComponent < ApplicationComponent
    def initialize
      @trial_key = Token::EnterpriseTrialKey.find_by(user_id: User.system.id)

      super
    end

    def render?
      User.current.admin? && !EnterpriseToken.active?
    end

    def call
      render(
        Primer::Beta::Button.new(
          tag: :a,
          href: trial_dialog_enterprise_trial_path,
          data: { turbo_stream: true }
        )
      ) do
        if @trial_key
          I18n.t("ee.trial.request_again")
        else
          I18n.t("admin.enterprise.start_trial")
        end
      end
    end
  end
end
