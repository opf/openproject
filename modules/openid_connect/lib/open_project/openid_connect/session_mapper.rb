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

module OpenProject::OpenIDConnect
  class SessionMapper
    def self.handle_logout(logout_token)
      link = ::OpenIDConnect::UserSessionLink.find_by(oidc_session: logout_token.sid)
      new(link).expire!
    rescue StandardError => e
      Rails.logger.error { "Failed to handle OIDC session logout: #{e.message}" }
      raise e
    end

    def self.handle_login(session)
      oidc_session = session["omniauth.oidc_sid"]
      return if oidc_session.blank?

      link = ::OpenIDConnect::UserSessionLink.new(oidc_session:)
      new(link).link_to_internal!(session)
    rescue StandardError => e
      Rails.logger.error { "Failed to map OIDC session to internal: #{e.message}" }
    end

    attr_reader :session_link

    delegate :oidc_session, to: :session_link, allow_nil: true

    def initialize(link)
      @session_link = link
    end

    ##
    # Link the oidc session to the given user session
    def link_to_internal!(session)
      delete_old_links!

      user_session = find_user_session(session)

      if user_session
        Rails.logger.debug { "Linking #{oidc_session} to session #{session.id}" }
        session_link.session_id = user_session.id
        session_link.save!
      else
        Rails.logger.warn { "No user session present to link oidc session to. AR Sessions are required" }
      end
    end

    def delete_old_links!
      ::OpenIDConnect::UserSessionLink.where(oidc_session:).delete_all
    end

    def find_user_session(session)
      private_session_id = session.id.private_id
      ::Sessions::UserSession.find_by(session_id: private_session_id)
    end

    ##
    # Expire the associated session for the given oidc session
    def expire!
      if session_link
        Rails.logger.debug { "Expiring user session for OIDC sid #{oidc_session} due to backchannel request." }
        remove_linked_session!
      else
        Rails.logger.debug { "No session link found for #{oidc_session}." }
      end
    end

    private

    def remove_linked_session!
      if session_link.session
        Rails.logger.debug { "Deleting linked session for #{oidc_session}" }
        session_link.session.delete
      else
        Rails.logger.debug { "Found session link, but no active user session for #{oidc_session}." }
      end
    end
  end
end
