#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
require "ostruct"

##
# Service state object to be passed around services
# for remembering state between service calls (e.g., when copying).
#
# Borrows heavily from interactor gem's context class at
# https://github.com/collectiveidea/interactor
module Shared
  class ServiceState < OpenStruct
    ##
    # Builds the context object unless
    # it's already an instance of this context.
    def self.build(state = {})
      self === state ? state : new(state)
    end

    ##
    # Remember that the state was passed to the given service
    def called!(service)
      service_chain << service
    end

    # Roll back the context on all used services
    def rollback!
      return false if @rolled_back

      service_chain.reverse_each do |service|
        Rails.logger.debug { "[Service state] Rolling back execution of #{service}." }
        service.rollback
      end
      @rolled_back = true
    end

    # Remembered service calls this context was used against
    def service_chain
      @service_chain ||= []
    end
  end
end
