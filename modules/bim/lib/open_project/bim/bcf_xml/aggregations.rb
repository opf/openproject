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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Bim::BcfXml
  class Aggregations
    attr_reader :listings, :project, :instance_cache

    def initialize(listing, project)
      @listings = listing
      @project = project

      @instance_cache = {}
    end

    def all_people
      @instance_cache[:all_people] ||= listings.pluck(:people).flatten.uniq
    end

    def all_mails
      @instance_cache[:all_mails] ||= listings.pluck(:mail_addresses).flatten.uniq
    end

    def known_users
      @instance_cache[:known_users] ||= User.where(mail: all_mails).includes(:memberships)
    end

    def unknown_mails
      @instance_cache[:unknown_mails] ||= all_mails.map(&:downcase) - known_users.map(&:mail).map(&:downcase)
    end

    def members
      @instance_cache[:members] ||= known_users.select { |user| user.projects.map(&:id).include? @project.id }
    end

    def non_members
      @instance_cache[:non_members] ||= known_users - members
    end

    def invalid_people
      @instance_cache[:invalid_people] ||= all_people - all_mails
    end

    def all_statuses
      @instance_cache[:all_statuses] ||= listings.pluck(:status).flatten.uniq
    end

    def unknown_statuses
      @instance_cache[:unknown_statuses] ||= all_statuses - Status.all.map(&:name)
    end

    def all_types
      @instance_cache[:all_types] ||= listings.pluck(:type).flatten.uniq
    end

    def unknown_types
      @instance_cache[:unknown_types] ||= all_types - Type.all.map(&:name)
    end

    def all_priorities
      @instance_cache[:all_priorities] ||= listings.pluck(:priority).flatten.uniq
    end

    def unknown_priorities
      @instance_cache[:unknown_priorities] ||= all_priorities - IssuePriority.all.map(&:name)
    end

    def clear_instance_cache
      @instance_cache = {}
    end
  end
end
