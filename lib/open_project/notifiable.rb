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

module OpenProject
  NOTIFIABLE = [
    %w(work_package_added),
    %w(work_package_updated),
    %w(work_package_note_added work_package_updated),
    %w(status_updated work_package_updated),
    %w(work_package_priority_updated work_package_updated),
    %w(news_added),
    %w(news_comment_added),
    %w(file_added),
    %w(message_posted),
    %w(wiki_content_added),
    %w(wiki_content_updated),
    %w(membership_added),
    %w(membership_updated)
  ].freeze

  Notifiable = Struct.new(:name, :parent) do
    def to_s
      name
    end

    # TODO: Plugin API for adding a new notification?
    def self.all
      OpenProject::NOTIFIABLE.map do |event_strings|
        Notifiable.new(*event_strings)
      end
    end
  end
end
