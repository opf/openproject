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
      class NewComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable
        include WorkPackages::ActivitiesTab::StimulusControllers

        def initialize(work_package:, filter:, last_server_timestamp:, journal: nil, form_hidden_initially: true)
          super

          @work_package = work_package
          @filter = filter
          @last_server_timestamp = last_server_timestamp
          @journal = journal
          @form_hidden_initially = form_hidden_initially
        end

        private

        attr_reader :work_package, :filter, :last_server_timestamp, :form_hidden_initially

        def journal
          @journal || Journal.new(journable: work_package)
        end

        def button_row_display_value
          form_hidden_initially ? :block : :none
        end

        def form_row_display_value
          form_hidden_initially ? :none : :block
        end

        def adding_internal_comment_allowed?
          EnterpriseToken.allows_to?(:internal_comments) &&
            work_package.project.enabled_internal_comments &&
            User.current.allowed_in_project?(:add_internal_comments, work_package.project)
        end

        def learn_more_static_link_url
          ::OpenProject::Static::Links.url_for(:enterprise_features, :internal_comments)
        end

        def confirm_dialog_data_attributes
          {
            internal_comment_stimulus_controller("-target") => "confirmationDialog"
          }
        end
      end
    end
  end
end
