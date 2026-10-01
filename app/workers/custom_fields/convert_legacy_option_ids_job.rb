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

module CustomFields
  # Rewrites the list option ids still held by saved objects to the ids of the
  # items that replaced them, leaving LegacyOptionIdResolver to serve only what
  # OpenProject does not store, such as bookmarked filter URLs. Loading a record
  # resolves its ids, so saving it is the conversion; unchanged records are skipped
  # by dirty tracking.
  class ConvertLegacyOptionIdsJob < ApplicationJob
    queue_with_priority :default

    def perform
      return unless CustomField::LegacyOptionMapping.exists?

      resave(Query.where("filters LIKE '%cf\\_%'"), :filters)
      resave(ProjectQuery.where("filters::text LIKE '%cf\\_%'"), :filters)
      # Cost report queries share the table but filter list fields by label.
      resave(UserQuery.where("filters::text LIKE '%cf\\_%'"), :filters)
      resave(CustomAction.where("actions LIKE '%custom\\_field\\_%'"), :actions)
    end

    private

    def resave(scope, column)
      scope.find_each do |record|
        # Reloaded under a lock, so a concurrent save from the UI is not overwritten.
        record.with_lock do
          # Dirty tracking only compares a serialized attribute once it has been read.
          record[column]
          record.save!(validate: false, touch: false)
        end
      rescue StandardError => e
        OpenProject.logger.error("Could not convert legacy custom option ids of #{record.class} #{record.id}: " \
                                 "#{e.class}: #{e.message}")
      end
    end
  end
end
