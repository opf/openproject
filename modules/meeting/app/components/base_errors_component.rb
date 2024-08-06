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

class BaseErrorsComponent < ApplicationComponent
  include ApplicationHelper
  include OpTurbo::Streamable
  include OpPrimer::ComponentHelpers

  def initialize(object, keys: %w[base])
    super

    @errors = object.errors
    @keys = keys
  end

  def render?
    @keys.any? { |key| @errors[key].present? }
  end

  def call
    render(Primer::Alpha::Banner.new(scheme: :danger, icon: :stop, spacious: true)) do
      joined_messages
    end
  end

  def joined_messages
    messages = @keys.map { |key| @errors.full_messages_for(key) }.flatten
    helpers.safe_join(messages, "<br />".html_safe)
  end
end
