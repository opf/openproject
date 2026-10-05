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

module Screens
  class ScreenService
    class << self
      def create(params) = save(Screen.new, params)
      def update(screen, params) = save(screen, params)

      def clone(screen)
        copy = Screen.new(name: clone_name(screen),
                          description: screen.description,
                          screen_type: screen.screen_type,
                          active: false)
        screen.sections.order(:position, :id).each do |section|
          new_section = copy.sections.build(name: section.name, position: section.position)
          section.items.order(:position, :id).each do |item|
            new_section.items.build(field_key: item.field_key, position: item.position,
                                    width: item.width, visible: item.visible, screen: copy)
          end
        end
        copy.save ? ok(copy) : fail_with(copy)
      rescue ActiveRecord::RecordNotUnique
        copy.errors.add(:base, :conflict)
        fail_with(copy)
      end

      def activate(screen) = toggle(screen, true)
      def deactivate(screen) = toggle(screen, false)

      def impact(screen)
        rows = references(screen)
        scheme_ids = rows.distinct.select(:scheme_id)
        { scheme_count: rows.distinct.count(:scheme_id),
          project_count: ProjectScreenScheme.where(scheme_id: scheme_ids).distinct.count(:project_id),
          type_ids: rows.distinct.pluck(:type_id) }
      end

      private

      def references(screen)
        ScreenSchemeItem
          .where(create_screen_id: screen.id)
          .or(ScreenSchemeItem.where(edit_screen_id: screen.id))
          .or(ScreenSchemeItem.where(view_screen_id: screen.id))
          .or(ScreenSchemeItem.where(transition_screen_id: screen.id))
      end

      def toggle(screen, active)
        screen.update(active:) ? ok(screen) : fail_with(screen)
      end

      def clone_name(screen)
        base = I18n.t("screens.copy_of", name: screen.name)
        candidates = [base] + (2..).lazy.map { |n| "#{base} #{n}" }
        candidates.find { |name| !Screen.exists?(name:) }
      end

      def save(screen, params)
        return screen_type_readonly(screen) if immutable_type_change?(screen, params)

        result = nil
        Screen.transaction do
          screen.lock! if screen.persisted?
          screen.assign_attributes(params.slice(:name, :description, :active))
          screen.screen_type = params[:screen_type] if screen.new_record? && params[:screen_type].present?

          if screen.save
            result = persist_layout(screen, params)
          else
            result = fail_with(screen)
          end
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      rescue ActiveRecord::RecordNotUnique
        screen.errors.add(:base, :conflict)
        fail_with(screen)
      end

      def persist_layout(screen, params)
        return ok(screen) unless params.key?(:sections)

        layout = LayoutService.replace(screen, params[:sections])
        return ok(screen) if layout.success?

        screen.errors.merge!(layout.errors)
        fail_with(screen)
      end

      def immutable_type_change?(screen, params)
        screen.persisted? && params[:screen_type].present? && params[:screen_type].to_s != screen.screen_type
      end

      def screen_type_readonly(screen)
        screen.errors.add(:screen_type, :readonly)
        fail_with(screen)
      end

      def ok(result) = ServiceResult.success(result:)
      def fail_with(model) = ServiceResult.failure(result: model, errors: model.errors)
    end
  end
end
