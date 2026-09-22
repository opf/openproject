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

module Backlogs
  module WorkPackages
    class BatchMoveParamsContract < ::ParamsContract
      validate :ids_distinct_and_present
      validate :batch_within_cap
      validate :target_resolvable
      validate :predecessor_well_formed

      # BaseContract#errors returns model.errors whenever the model responds
      # to it, and project does: without this override, validating the
      # contract would clear and repopulate the live project's own error bag.
      def errors
        @errors ||= ActiveModel::Errors.new(self)
      end

      private

      def ids
        Array(params[:ids]).map(&:to_s)
      end

      def ids_distinct_and_present
        return unless ids.empty? || ids.any?(&:blank?) || ids.uniq.length != ids.length

        errors.add(:base, I18n.t("backlogs.work_packages.move_collection.invalid_ids"))
      end

      def batch_within_cap
        return if ids.length <= BatchUpdateService::MAX_BATCH_SIZE

        errors.add(:base, I18n.t("backlogs.work_packages.move_collection.too_many_work_packages",
                                 max: BatchUpdateService::MAX_BATCH_SIZE))
      end

      def target_resolvable
        return if Backlogs::Target.from_list(params[:list_type], params[:list_id])

        errors.add(:base, I18n.t("backlogs.work_packages.update_service.invalid_target_type"))
      end

      # A nonblank prev_id must be a pure integer id, or Active Record would
      # integer-cast a digit-prefixed string; and a member cannot anchor its
      # own batch.
      def predecessor_well_formed
        prev_id = params[:prev_id]
        return if prev_id.nil? || prev_id.to_s.blank?
        return if prev_id.to_s.match?(/\A\d+\z/) && ids.exclude?(prev_id.to_s)

        errors.add(:base, I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor"))
      end
    end
  end
end
