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

module Bim::Bcf::API::V2_1
  class Comments::SingleRepresenter < BaseRepresenter
    include API::Decorators::DateProperty

    property :uuid,
             as: :guid

    property :date,
             getter: ->(represented:, decorator:, **) {
               decorator.datetime_formatter.format_datetime(represented.journal.created_at, allow_nil: true)
             }

    property :author,
             getter: ->(represented:, **) {
               represented.journal.user.mail
             }

    property :comment,
             getter: ->(represented:, **) {
               represented.journal.notes
             }

    property :topic_guid,
             getter: ->(represented:, **) {
               represented.issue.uuid
             }

    # not required properties
    property :viewpoint_guid,
             getter: ->(represented:, **) {
               represented.viewpoint&.uuid
             }

    property :reply_to_comment_guid,
             getter: ->(represented:, **) {
               represented.reply_to&.uuid
             }

    property :modified_date,
             getter: ->(represented:, decorator:, **) {
               decorator.datetime_formatter.format_datetime(represented.journal.updated_at, allow_nil: true)
             }

    # we do not store the author when editing a journal, hence the "modified author" is the same as the creator
    property :modified_author,
             getter: ->(represented:, **) {
               represented.journal.user.mail
             }

    property :authorization,
             getter: ->(represented:, **) {
               contract = WorkPackages::UpdateContract.new(represented.issue.work_package, User.current)
               Comments::AuthorizationRepresenter.new(contract)
             }
  end
end
