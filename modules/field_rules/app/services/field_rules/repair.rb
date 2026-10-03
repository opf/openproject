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
# frozen_string_literal: true

module FieldRules
  class Repair
    Report = Struct.new(:orphan_rules, :invalid_rules, :dry_run, keyword_init: true)

    def self.call(dry_run: true) = new(dry_run:).call

    def initialize(dry_run:)
      @dry_run = dry_run
    end

    def call
      orphans = orphan_custom_field_rules
      invalid = rules_with_invalid_state
      apply(orphans, invalid) unless @dry_run
      Resolver.reset_cache
      Report.new(orphan_rules: orphans.size, invalid_rules: invalid.size, dry_run: @dry_run)
    end

    private

    def orphan_custom_field_rules
      existing = WorkPackageCustomField.pluck(:id).to_set
      FieldRule.where("field_key LIKE 'custom_field_%'").select do |rule|
        id = Fields.custom_field_id(rule.field_key)
        id.nil? || existing.exclude?(id)
      end
    end

    def rules_with_invalid_state
      FieldRule.where(hidden: true, required: true).or(FieldRule.where(hidden: true, read_only: true)).to_a
    end

    def apply(orphans, invalid)
      FieldRule.transaction do
        FieldRule.where(id: orphans.map(&:id)).delete_all
        FieldRule.where(id: invalid.map(&:id)).update_all(required: false, read_only: false)
      end
    end
  end
end
