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

module API
  module V3
    module Utilities
      module ResourceLinkGenerator
        class << self
          include ::API::V3::Utilities::PathHelper

          def make_link(record)
            if record.respond_to?(:id)
              path_method = determine_path_method(record)
              record_identifier = record.id
              api_v3_paths.send(path_method, record_identifier)
            elsif record.is_a?(String)
              api_v3_paths.string_object(record)
            end
          rescue NoMethodError
            nil
          end

          private

          def determine_path_method(record)
            # since not all things are equally named between APIv3 and the rails code,
            # we need to convert some names manually
            case record
            when IssuePriority
              :priority
            when AnonymousUser, DeletedUser, SystemUser
              :user
            when Journal, Journal::AggregatedJournal
              :activity
            when Changeset
              :revision
            else
              record.class.model_name.singular
            end
          end
        end
      end
    end
  end
end
