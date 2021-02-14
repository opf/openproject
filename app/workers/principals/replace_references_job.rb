#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Principals
  class ReplaceReferencesJob < ApplicationJob
    queue_with_priority :low

    def perform(principal_id)
      reassign_author principal_id
      reassign_user_id principal_id
      reassign_user_custom_values principal_id

      Journals::PrincipalReferenceUpdateService
        .new(principal_id)
        .call(substitute)
    end

    private

    def substitute
      @substitute ||= DeletedUser.first
    end

    def reassign_author(id)
      [WorkPackage, Attachment, WikiContent, News, Comment, Message].each do |klass|
        klass
          .where(author_id: id)
          .update_all(author_id: substitute.id)
      end
    end

    def reassign_user_id(id)
      [TimeEntry, ::Query].each do |klass|
        klass
          .where(user_id: id)
          .update_all(user_id: substitute.id)
      end
    end

    def reassign_user_custom_values(id)
      CustomValue
        .joins(:custom_field)
        .where("#{CustomField.table_name}.field_format" => 'user')
        .where(value: id.to_s)
        .update_all(value: substitute.id)
    end
  end
end
