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

module Sessions
  class AutologinSessionLink < ApplicationRecord
    belongs_to :token, class_name: "Token::AutoLogin"
    belongs_to :session, class_name: "Sessions::UserSession"

    before_destroy :delete_sessions

    private

    ##
    # When the session link is destroyed (because the autologin token got destroyed),
    # linked sessions should be destroyed. As the sessions table is unlogged for performance reasons,
    # we cannot use a foreign key on_delete constraint but have to do it manually here.
    def delete_sessions
      Sessions::UserSession.where(id: session_id).delete_all
    end
  end
end
