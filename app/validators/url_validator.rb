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

# Borrows from http://gist.github.com/bf4/5320847
# without addressable requirement
# Accepts options[:allowed_protocols]
class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    url = parse(value)

    if url.nil?
      record.errors.add(attribute, :invalid_url)
    elsif !allowed_protocols.include?(url.scheme)
      record.errors.add(attribute, :invalid_url_scheme, allowed_schemes: allowed_protocols.join(", "))
    end
  end

  def parse(value)
    URI.parse(value.to_s.strip)
  rescue StandardError
    nil
  end

  def allowed_protocols
    options.fetch(:allowed_protocols, %w(http https))
  end
end
