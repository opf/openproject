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

module TestManagement
  class TestCasesQuery
    PARAM_KEYS = %i[suite_id q status priority automated].freeze

    attr_reader :project, :params

    def initialize(project, params = {}, suites: nil)
      @project = project
      @params = normalize(params)
      @suites = suites
    end

    def suites
      @suites ||= project.tm_suites.to_a
    end

    def unfiled?
      params[:suite_id] == "root"
    end

    def folder?
      params[:suite_id].present?
    end

    def filters?
      params.slice(:q, :status, :priority, :automated).values.any?(&:present?)
    end

    def suite
      return if !folder? || unfiled?

      @suite ||= suites.find { |s| s.id.to_s == params[:suite_id].to_s }
    end

    def results
      apply_attributes(apply_search(apply_folder(project.tm_test_cases)))
    end

    private

    def normalize(params)
      hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      hash = hash.symbolize_keys.slice(*PARAM_KEYS)
      hash.transform_values { |value| value.is_a?(String) ? value.strip : value&.to_s }
    end

    def apply_folder(relation)
      return relation unless folder?
      return relation.where(suite_id: nil) if unfiled?

      relation.where(suite_id: suite ? Suite.subtree_ids(project, [suite.id]) : nil)
    end

    def apply_search(relation)
      return relation if params[:q].blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
      relation.where("tm_test_cases.title ILIKE ?", pattern)
    end

    def apply_attributes(relation) # rubocop:disable Metrics/AbcSize
      relation = relation.where(status: params[:status]) if params[:status].present?
      relation = relation.where(priority: params[:priority]) if params[:priority].present?
      relation = relation.where(automated: ActiveModel::Type::Boolean.new.cast(params[:automated])) if params[:automated].present?
      relation
    end
  end
end
