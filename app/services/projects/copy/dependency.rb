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

module Projects::Copy
  class Dependency < ::Copy::Dependency
    delegate :should_copy?, to: :class

    ##
    # Allow to count the source dependency count
    # if applicable
    def source_count
      nil
    end

    ##
    # Check whether this dependency should be copied
    # as it was selected
    def self.should_copy?(params, check)
      return false if params[:only].blank?

      params[:only].any? { |key| key.to_sym == check }
    end

    protected

    ##
    # Copy every record of the named +association+ from the source project to
    # the target, returning a Hash mapping each source record id to its copy's
    # id. Uses the non-raising +create+ (as VersionsDependentService does) so a
    # single invalid record is skipped rather than aborting the whole copy.
    #
    # When a block is given, its return value is merged into the copied
    # attributes, letting a caller carry over child records via nested
    # attributes (see SprintsDependentService copying sprint goals).
    def copy_collection_with_id_map(association)
      source.public_send(association).each_with_object({}) do |source_record, id_map|
        attributes = copyable_attributes(source_record)
        attributes.merge!(yield(source_record)) if block_given?
        copy = target.public_send(association).create(attributes)
        id_map[source_record.id] = copy.id if copy.persisted?
      end
    end

    def copyable_attributes(source_record)
      source_record.attributes.dup.except("id", "project_id", "created_at", "updated_at")
    end
  end
end
