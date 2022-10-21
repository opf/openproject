# --copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2022 the OpenProject GmbH
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
# ++

module API::V3::Notifications
  module DetailsFactory
    extend ::API::V3::Utilities::PathHelper

    module_function

    def for(notification)
      concrete_factory_for(notification.reason)
        .for(notification)
    end

    def concrete_factory_for(reason)
      @concrete_factory_for ||= Hash.new do |h, reason_key|
        h[reason_key] = if API::V3::Notifications::DetailsFactory.const_defined?(reason_key.camelcase)
                          "API::V3::Notifications::DetailsFactory::#{reason_key.camelcase}".constantize
                        else
                          API::V3::Notifications::DetailsFactory::Default
                        end
      end

      @concrete_factory_for[reason]
    end
  end
end
