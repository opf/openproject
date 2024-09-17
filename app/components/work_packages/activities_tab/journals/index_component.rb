# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
    module Journals
      class IndexComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(work_package:, filter: :all)
          super

          @work_package = work_package
          @filter = filter
        end

        private

        attr_reader :work_package, :filter

        def insert_target_modified?
          true
        end

        def insert_target_modifier_id
          "work-package-journal-days"
        end

        def journal_sorting
          User.current.preference&.comments_sorting || "desc"
        end

        def journals
          work_package.journals.includes(:user, :notifications).reorder(version: journal_sorting)
        end

        def journal_with_notes
          journals.where.not(notes: "")
        end

        def empty_state?
          filter == :only_comments && journal_with_notes.empty?
        end

        def inner_container_margin_bottom
          if journal_sorting == "desc"
            3
          else
            0
          end
        end
      end
    end
  end
end
