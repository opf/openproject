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

class Principals::DeleteJob < ApplicationJob
  queue_with_priority :below_normal

  def perform(principal)
    Principal.transaction do
      delete_associated(principal)
      replace_references(principal)
      replace_mentions(principal)
      update_cost_queries(principal)
      remove_members(principal)

      principal.destroy
    end
  end

  private

  def replace_references(principal)
    Principals::ReplaceReferencesService
      .new
      .call(from: principal, to: DeletedUser.first)
      .on_failure { raise ActiveRecord::Rollback }
  end

  def replace_mentions(principal)
    # Breaking abstraction here.
    # Doing the replacement is a very costly operation while at the same time,
    # placeholder users can't be mentioned.
    return unless principal.is_a?(User) || principal.is_a?(Group)

    Users::ReplaceMentionsService
      .new
      .call(from: principal, to: DeletedUser.first)
      .on_failure { raise ActiveRecord::Rollback }
  end

  def delete_associated(principal)
    delete_notifications(principal)
    delete_private_queries(principal)
    delete_private_persisted_views(principal)
    nullify_persisted_query_principals(principal)
    delete_user_ordered_query_entities(principal)
    delete_tokens(principal)
    delete_favorites(principal)
  end

  def delete_notifications(principal)
    ::ReminderNotification.joins(:notification)
                         .where(notifications: { recipient: principal })
                         .delete_all

    ::Notification.where(recipient: principal).delete_all
  end

  def delete_private_queries(principal)
    ::Query.where(user_id: principal.id, public: false).destroy_all
    CostQuery.where(user_id: principal.id, is_public: false).delete_all
  end

  # Private persisted views belong to their owner and are removed with them.
  # Public views are kept, but their principal reference is nullified so the
  # view becomes "ownerless" rather than pointing at the soon-to-be-deleted
  # user. Destroying the private views also triggers the view's after_destroy
  # hook, which cleans up queries that are no longer referenced by any public
  # view.
  def delete_private_persisted_views(principal)
    PersistedView.where(principal_id: principal.id, public: false).destroy_all
    PersistedView.where(principal_id: principal.id, public: true).update_all(principal_id: nil)
  end

  # Queries have no public/private flag — their visibility is derived from the
  # views that reference them. Any query still reachable after the view
  # cleanup above stays; we just drop the owner pointer.
  def nullify_persisted_query_principals(principal)
    PersistedQuery.where(principal_id: principal.id).update_all(principal_id: nil)
  end

  # Manually curated entries that point at the deleted user are dropped — a
  # list of "Deleted user, Deleted user, …" is worse than just removing them.
  def delete_user_ordered_query_entities(principal)
    OrderedPersistedQueryEntity.where(entity: principal).delete_all
  end

  def delete_favorites(principal)
    Favorite.where(user_id: principal.id).delete_all
  end

  def delete_tokens(principal)
    ::Token::Base.where(user_id: principal.id).destroy_all
  end

  def update_cost_queries(principal)
    CostQuery.in_batches.each_record do |query|
      serialized = query.serialized

      serialized[:filters] = serialized[:filters].filter_map do |name, options|
        remove_cost_query_values(name, options, principal)
      end

      CostQuery.where(id: query.id).update_all(serialized:)
    end
  end

  def remove_cost_query_values(name, options, principal)
    options[:values].delete(principal.id.to_s) if %w[UserId AuthorId AssignedToId ResponsibleId].include?(name)

    if options[:values].nil? || options[:values].any?
      [name, options]
    end
  end

  def remove_members(principal)
    principal.members.each do |member|
      Members::DeleteService
        .new(user: User.current, contract_class: EmptyContract, model: member)
        .call
    end
  end
end
