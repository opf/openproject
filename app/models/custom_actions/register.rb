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

module CustomActions
  module Register
    class << self
      def add(type, klass)
        raise "A #{type} '#{klass}' is already registered!" if [actions, conditions].flatten.include? klass

        case type
        when :condition
          conditions << klass
        when :action
          actions << klass
        else
          raise "Wrong type specified"
        end
      end

      def remove(klass)
        deletetion_result = [actions.delete(klass), conditions.delete(klass)].flatten.compact
        raise "A '#{klass}' wasn't registered!" if deletetion_result.blank?
      end

      def actions
        @actions ||= [
          CustomActions::Actions::AssignedTo,
          CustomActions::Actions::CustomField,
          CustomActions::Actions::Date,
          CustomActions::Actions::DoneRatio,
          CustomActions::Actions::DueDate,
          CustomActions::Actions::EstimatedHours,
          CustomActions::Actions::Notify,
          CustomActions::Actions::Project,
          CustomActions::Actions::Priority,
          CustomActions::Actions::Responsible,
          CustomActions::Actions::StartDate,
          CustomActions::Actions::Status,
          CustomActions::Actions::Type
        ]
      end

      def conditions
        @conditions ||= [
          CustomActions::Conditions::Project,
          CustomActions::Conditions::Role,
          CustomActions::Conditions::Status,
          CustomActions::Conditions::Type
        ]
      end
    end
  end
end
