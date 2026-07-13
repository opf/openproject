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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Users
  module WorkingHours
    class FormComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      FORM_ID = "working-hours-form"

      attr_reader :user, :working_hours, :show_valid_from

      def initialize(user:, working_hours:, show_valid_from: true, **)
        super(nil, **)
        @user = user
        @working_hours = working_hours
        @show_valid_from = show_valid_from
      end

      def form_url
        url_params = show_valid_from ? {} : { current: true }

        if working_hours.persisted?
          user_working_hour_path(user, working_hours, **url_params)
        else
          user_working_hours_path(user, **url_params)
        end
      end

      def form_options
        {
          model: working_hours,
          url: form_url,
          method: form_method,

          html: {
            id: FORM_ID,
            data: {
              turbo: true,
              controller: "users--working-hours-form"
            }
          }
        }
      end

      def form_method
        working_hours.persisted? ? :patch : :post
      end
    end
  end
end
