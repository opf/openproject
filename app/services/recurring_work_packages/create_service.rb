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

module RecurringWorkPackages
  class CreateService
    attr_reader :user, :work_package

    def initialize(user:, work_package:)
      @user = user
      @work_package = work_package
    end

    def call(params)
      series = Series.new(params.merge(project: work_package.project, author: user))
      series.errors.add(:base, :already_recurring) if Occurrence.exists?(work_package:)
      return failure(series) if series.errors.any?

      Series.transaction { persist(series) }
    end

    private

    def persist(series)
      return failure(series) unless series.save

      series.occurrences.create!(work_package:, position: 1, scheduled_date: series.start_date)
      work_package.touch
      add_note(series)

      ServiceResult.success(result: series)
    end

    def failure(series)
      ServiceResult.failure(result: series, errors: series.errors)
    end

    def add_note(series)
      notes = I18n.t("recurring_work_packages.notes.made_recurring",
                     schedule: series.schedule_in_words,
                     path: Rails.application.routes.url_helpers.project_recurring_work_package_path(series.project, series))

      AddWorkPackageNoteService
        .new(user:, work_package:)
        .call(notes, send_notifications: false)
    end
  end
end
