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

module Admin
  module TextTransformActions
    # Prototype only: serves the searchable item lists for the sandbox's
    # work package and project pickers.
    class SandboxController < ::ApplicationController
      include AI::TextTransformActionsFeature

      LIMIT = 20

      before_action :require_admin
      before_action :require_ai_text_transform_actions_feature

      def work_packages
        items = work_package_scope.order(updated_at: :desc).limit(LIMIT).map do |work_package|
          [work_package.id, work_package_label(work_package)]
        end
        render_items(items)
      end

      def projects
        scope = Project.visible(current_user).active
        scope = scope.where("projects.name ILIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
        items = scope.order(:name).limit(LIMIT).map { |project| [project.id, project.name] }
        render_items(items)
      end

      private

      def work_package_scope
        scope = WorkPackage.visible(current_user).includes(:project, :type)
        return scope if query.blank?

        matching = scope.where("work_packages.subject ILIKE ?", "%#{sanitize_sql_like(query)}%")
        query.match?(/\A\d+\z/) ? matching.or(scope.where(id: query.to_i)) : matching
      end

      def work_package_label(work_package)
        "##{work_package.id} #{work_package.subject} (#{work_package.project.name}, #{work_package.type.name})"
      end

      def query
        @query ||= params[:q].to_s.strip
      end

      def sanitize_sql_like(value)
        ActiveRecord::Base.sanitize_sql_like(value)
      end

      def render_items(items)
        list = Primer::Alpha::SelectPanel::ItemList.new
        items.each do |value, label|
          list.with_item(label:, content_arguments: { data: { value: } })
        end
        render html: list.render_in(view_context), layout: false
      end
    end
  end
end
