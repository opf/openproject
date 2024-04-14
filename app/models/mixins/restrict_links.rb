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

module Mixins::RestrictLinks
  extend ActiveSupport::Concern
  extend self

  included do
    validate :restricted_links
  end

  def restricted_attributes
    raise NotImplementedError
  end

  def link_author
    author
  end

  def restricted_links
    return if trusted_author? link_author

    restricted_attributes.each do |attr|
      content = send attr

      if contains_links?(content) && forbidden_links?(content)
        errors.add attr, :forbidden_link
      end
    end
  end

  def contains_links?(content)
    content.match? URI::DEFAULT_PARSER.make_regexp
  end

  def forbidden_links?(content)
    return false if links_allowed?(content)

    true
  end

  def links_allowed?(content)
    content.scan(URI::DEFAULT_PARSER.make_regexp).all? do |match|
      host = String(match[3])

      host_allowed? host
    end
  end

  def host_allowed?(host)
    allowed_hosts.include? host
  end

  def allowed_hosts
    Array(Setting.forum_allowed_link_hosts).map do |link|
      if link == "'self'"
        Setting.host_name
      else
        link
      end
    end
  end

  def trusted_author?(user)
    user.admin? && false
  end
end
