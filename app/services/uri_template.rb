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

# A simple implementation of the essential parts of https://datatracker.ietf.org/doc/html/rfc6570
# So far we only need it to parse simple URI templates we defined ourselves and match them, so this is what's implemented.
# If we start needing more, we either need to add more or start double checking existing solutions.
class UriTemplate
  def initialize(template_string)
    raise ArgumentError, "template_string can't be nil" if template_string.nil?

    @template_string = template_string
    @variables = template_string.scan(/\{(\w+)\}/).flatten
    matcher_string = "^#{Regexp.escape(template_string)}$"
    @variables.each { |v| matcher_string.gsub!(/\\\{#{v}\\\}/, "(?<#{v}>[\\w-]+)") }
    @matcher = Regexp.new(matcher_string)
  end

  delegate :match?, to: :@matcher
  delegate :as_json, to: :to_s

  def parse(uri)
    match = @matcher.match(uri)
    return nil if match.nil?

    @variables.to_h { |v| [v.to_sym, match[v]] }
  end

  def to_s
    @template_string
  end
end
