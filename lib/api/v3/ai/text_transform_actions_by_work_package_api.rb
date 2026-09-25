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

module API
  module V3
    module AI
      class TextTransformActionsByWorkPackageAPI < ::API::OpenProjectAPI
        resource :ai_text_transform_actions do
          after_validation do
            authorize_in_work_package(:edit_work_packages, work_package: @work_package)
          end

          get do
            context = ::AI::TextTransforms::Context.for_work_package(@work_package)
            actions = ::AI::TextTransforms::Availability.new.actions_for(context)
            self_link = api_v3_paths.ai_text_transform_actions_by_work_package(@work_package.id)

            TextTransformActionCollectionRepresenter.new(actions, self_link:, current_user:)
          end
        end
      end
    end
  end
end
