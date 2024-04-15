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
    delete_tokens(principal)
  end

  def delete_notifications(principal)
    ::Notification.where(recipient: principal).delete_all
  end

  def delete_private_queries(principal)
    ::Query.where(user_id: principal.id, public: false).destroy_all
    CostQuery.where(user_id: principal.id, is_public: false).delete_all
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
