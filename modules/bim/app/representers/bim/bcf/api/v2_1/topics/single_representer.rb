#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module Bim::Bcf::API::V2_1
  class Topics::SingleRepresenter < BaseRepresenter
    include API::V3::Utilities::PathHelper

    property :uuid,
             as: :guid

    property :type,
             as: :topic_type,
             getter: ->(*) {
               work_package
                 .type
                 .name
             }

    property :status,
             as: :topic_status,
             getter: ->(*) {
               work_package
                .status
                .name
             }

    property :priority,
             as: :priority,
             getter: ->(*) {
               work_package
                 .priority
                 .name
             }

    property :reference_links,
             getter: ->(decorator:, **) {
               [decorator.api_v3_paths.work_package(work_package.id)]
             }

    property :title,
             getter: ->(*) {
               work_package.subject
             }

    property :index

    property :labels

    property :creation_date,
             getter: ->(decorator:, **) {
               decorator
                 .formatted_date_time(:created_at)
             }

    property :creation_author,
             getter: ->(*) {
               work_package
                 .author
                 .mail
             }

    property :modified_date,
             getter: ->(decorator:, **) {
               decorator
                 .formatted_date_time(:updated_at)
             }

    property :modified_author,
             getter: ->(*) {
               work_package
                 .journals
                 .max_by(&:version)
                 .user
                 &.mail
             }

    property :assignee,
             as: :assigned_to,
             getter: ->(decorator:, **) {
               decorator
                 .assigned_to
                 &.mail
             }

    property :stage

    property :description,
             getter: ->(*) {
               work_package.description
             }

    property :due_date,
             getter: ->(decorator:, **) {
               decorator.datetime_formatter.format_date(work_package.due_date, allow_nil: true)
             },
             setter: ->(fragment:, decorator:, **) {
               date = decorator
                        .datetime_formatter
                        .parse_date(fragment,
                                    due_date,
                                    allow_nil: true)

               self.due_date = date
             }

    # Required only so that we can register a user wanting to set the snippets. We do not support setting it though.
    property :bim_snippet,
             skip_render: true

    property :authorization,
             getter: ->(*) {
               contract = WorkPackages::UpdateContract.new(work_package, User.current)

               Topics::AuthorizationRepresenter.new(contract)
             }

    def datetime_formatter
      ::API::V3::Utilities::DateTimeFormatter
    end

    def formatted_date_time(method)
      datetime_formatter
        .format_datetime(represented.work_package.send(method), allow_nil: true)
    end

    def assigned_to
      represented
        .work_package
        .assigned_to
    end
  end
end
