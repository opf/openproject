#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# Rewrites references to a principal from one principal to the other.
# No data is to be removed.
module Principals
  class ReplaceReferencesService
    def call(from:, to:)
      rewrite_active_models(from, to)
      rewrite_custom_value(from, to)
      rewrite_default_journals(from, to)
      rewrite_customizable_journals(from, to)

      ServiceResult.success
    end

    private

    def rewrite_active_models(from, to)
      rewrite_author(from, to)
      rewrite_user(from, to)
      rewrite_assigned_to(from, to)
      rewrite_responsible(from, to)
      rewrite_actor(from, to)
      rewrite_owner(from, to)
      rewrite_logged_by(from, to)
    end

    def rewrite_custom_value(from, to)
      CustomValue
        .where(custom_field_id: CustomField.where(field_format: 'user'))
        .where(value: from.id.to_s)
        .update_all(value: to.id.to_s)
    end

    def rewrite_default_journals(from, to)
      journal_classes.each do |klass|
        foreign_keys.each do |foreign_key|
          if klass.column_names.include? foreign_key
            rewrite(klass, foreign_key, from, to)
          end
        end
      end
    end

    def rewrite_customizable_journals(from, to)
      Journal::CustomizableJournal
        .joins(:custom_field)
        .where(custom_fields: { field_format: 'user' })
        .where(value: from.id.to_s)
        .update_all(value: to.id.to_s)
    end

    def rewrite_author(from, to)
      [WorkPackage,
       Attachment,
       WikiPage,
       News,
       Comment,
       Message,
       Budget,
       MeetingAgenda,
       MeetingMinutes,
       MeetingAgendaItem].each do |klass|
        rewrite(klass, :author_id, from, to)
      end
    end

    def rewrite_user(from, to)
      [TimeEntry,
       CostEntry,
       ::Query,
       Changeset,
       CostQuery,
       MeetingParticipant].each do |klass|
        rewrite(klass, :user_id, from, to)
      end
    end

    def rewrite_actor(from, to)
      [::Notification].each do |klass|
        rewrite(klass, :actor_id, from, to)
      end
    end

    def rewrite_owner(from, to)
      [::Doorkeeper::Application].each do |klass|
        rewrite(klass, :owner_id, from, to)
      end
    end

    def rewrite_assigned_to(from, to)
      [WorkPackage].each do |klass|
        rewrite(klass, :assigned_to_id, from, to)
      end
    end

    def rewrite_responsible(from, to)
      [WorkPackage].each do |klass|
        rewrite(klass, :responsible_id, from, to)
      end
    end

    def rewrite_logged_by(from, to)
      [
        TimeEntry,
        CostEntry
      ].each do |klass|
        rewrite(klass, :logged_by_id, from, to)
      end
    end

    def journal_classes
      [Journal] + Journal::BaseJournal.subclasses
    end

    def foreign_keys
      %w[author_id user_id assigned_to_id responsible_id logged_by_id]
    end

    def rewrite(klass, attribute, from, to)
      klass.where(attribute => from.id).update_all(attribute => to.id)
    end
  end
end
