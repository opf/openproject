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

module Messages
  class FormErrorsComponent < ApplicationComponent
    FIELD_ATTRIBUTES = %i[subject content sticky locked forum_id].freeze

    def initialize(message:)
      super
      @message = message
    end

    def render? = error_messages.any?

    def call
      render(Primer::Alpha::Banner.new(mb: 3, icon: :stop, scheme: :danger, test_selector: "message-form-errors")) do
        safe_join(error_messages, tag.br)
      end
    end

    private

    def error_messages
      @error_messages ||= @message.errors.reject { it.attribute.in?(FIELD_ATTRIBUTES) }.map(&:full_message)
    end
  end
end
