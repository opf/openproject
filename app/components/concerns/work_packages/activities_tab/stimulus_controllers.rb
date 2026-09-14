# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages
  module ActivitiesTab
    module StimulusControllers
      module_function

      def auto_scrolling_stimulus_controller(suffix = nil) = "#{stimulus_controller_namespace}--auto-scrolling#{suffix}"
      def editor_stimulus_controller(suffix = nil) = "#{stimulus_controller_namespace}--editor#{suffix}"
      def index_stimulus_controller(suffix = nil) = "#{stimulus_controller_namespace}--index#{suffix}"
      def internal_comment_stimulus_controller(suffix = nil) = "#{stimulus_controller_namespace}--internal-comment#{suffix}"
      def lazy_page_stimulus_controller(suffix = nil) = "#{stimulus_controller_namespace}--lazy-page#{suffix}"
      def polling_stimulus_controller(suffix = nil) = "#{stimulus_controller_namespace}--polling#{suffix}"
      def quote_comments_stimulus_controller(suffix = nil) = "#{stimulus_controller_namespace}--quote-comment#{suffix}"

      def index_component_dom_selector
        "##{WorkPackages::ActivitiesTab::LazyIndexComponent.index_content_wrapper_key}"
      end

      def add_comment_component_dom_selector
        "##{WorkPackages::ActivitiesTab::LazyIndexComponent.add_comment_wrapper_key}"
      end

      def stimulus_controller_namespace = "work-packages--activities-tab"
    end
  end
end
