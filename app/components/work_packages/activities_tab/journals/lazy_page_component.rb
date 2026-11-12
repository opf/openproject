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

module WorkPackages
  module ActivitiesTab
    module Journals
      class LazyPageComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable
        include WorkPackages::ActivitiesTab::StimulusControllers

        def initialize(work_package:, page:)
          super
          @work_package = work_package
          @page = page
        end

        def self.wrapper_key
          WorkPackages::ActivitiesTab::Journals::PageComponent.wrapper_key
        end

        def wrapper_uniq_by
          page
        end

        private

        attr_reader :work_package, :page

        def wrapper_data_attributes
          {
            controller: lazy_page_stimulus_controller,
            lazy_page_stimulus_controller("-page-value") => page,
            lazy_page_stimulus_controller("-url-value") => page_streams_url,
            lazy_page_stimulus_controller("-is-loaded-value") => false
          }
        end

        def page_streams_url
          page_streams_work_package_activities_path(work_package, format: :turbo_stream)
        end
      end
    end
  end
end
