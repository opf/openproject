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

module TypeSchemes
  # Creates the work package types named in a type scheme form or API payload.
  #
  # Names matching an existing type (case-insensitively) reuse that type instead
  # of creating a duplicate, so submitting "Sub-Tasks" twice is idempotent.
  class TypeCreator
    MAX_NAMES = 50

    def self.call(names) = new(names).call

    def initialize(names)
      @names = normalize(names)
    end

    def call
      return ServiceResult.success(result: []) if names.empty?
      return too_many if names.size > MAX_NAMES

      types = []
      names.each do |name|
        result = find_or_create(name)
        return result if result.failure?

        types << result.result
      end

      ServiceResult.success(result: types)
    end

    private

    attr_reader :names

    def normalize(names)
      Array(names)
        .filter_map { |name| name.to_s.strip.presence }
        .uniq { |name| name.downcase }
    end

    def find_or_create(name)
      existing = find_existing(name)
      return ServiceResult.success(result: existing) if existing

      create_type(name)
    end

    def find_existing(name)
      Type.where("LOWER(name) = ?", name.downcase).first
    end

    def create_type(name)
      WorkPackageTypes::CreateService.new(user: User.current).call(name:)
    rescue ActiveRecord::RecordNotUnique
      # Another request created the type between our lookup and the insert.
      existing = find_existing(name)
      return ServiceResult.success(result: existing) if existing

      raise
    end

    def too_many
      type = Type.new
      type.errors.add(:base, I18n.t("type_schemes.form.too_many_new_types", count: MAX_NAMES))
      ServiceResult.failure(result: type, errors: type.errors)
    end
  end
end
