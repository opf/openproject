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

module WorkPackages
  module ActivitiesTab
    module Journals
      class ItemComponent::Actions < ApplicationComponent
        include WorkPackages::ActivitiesTab::StimulusControllers

        def initialize(journal)
          super

          @journal = journal
        end

        def self.menu_id(journal)
          "wp-journal-#{journal.id}-action-menu"
        end

        def menu_id
          self.class.menu_id(journal)
        end

        private

        attr_reader :journal

        def editable?
          journal.editable_by?(User.current)
        end

        def quotable?
          journal.notes.present? && allowed_to_quote?
        end

        def allowed_to_quote?
          User.current.allowed_in_project?(:add_work_package_comments, journal.journable.project)
        end

        def edit_action_label
          if journal.user == User.current
            I18n.t("js.label_edit_comment")
          else
            I18n.t("js.label_moderate_comment")
          end
        end

        def quote_action_data_attributes # rubocop:disable Metrics/AbcSize
          {
            test_selector: "op-wp-journal-#{journal.id}-quote",
            controller: quote_comments_stimulus_controller,
            action: "click->#{quote_comments_stimulus_controller}#quote:prevent",
            quote_comments_stimulus_controller("-content-param") => journal.notes,
            quote_comments_stimulus_controller("-user-id-param") => journal.user_id,
            quote_comments_stimulus_controller("-user-name-param") => journal.user.name,
            quote_comments_stimulus_controller("-is-internal-param") => journal.internal?,
            quote_comments_stimulus_controller("-text-wrote-param") => I18n.t(:text_wrote),
            quote_comments_stimulus_controller("-#{internal_comment_stimulus_controller}-outlet") => add_comment_component_dom_selector, # rubocop:disable Layout/LineLength
            quote_comments_stimulus_controller("-#{editor_stimulus_controller}-outlet") => index_component_dom_selector
          }
        end
      end
    end
  end
end
