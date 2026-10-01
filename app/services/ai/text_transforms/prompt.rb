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

module AI
  module TextTransforms
    class Prompt
      SCAFFOLD = <<~TEXT.squish
        You are a writing assistant for project management work packages.
        Rules that always apply: return the full revised document as markdown, no code fences, no commentary;
        do not invent content the author did not state; preserve the exact casing of product names and versions;
        respond in the same language as the user's content, unless the task instructions explicitly state otherwise.
      TEXT
      TEMPLATE_INTRO = "The work package type's template, keep its structure:"

      Messages = Data.define(:system, :user)

      def self.build(action:, context:, content:)
        system = "#{SCAFFOLD}\n\n#{action.prompt}"
        template = context.template
        system = "#{system}\n\n#{TEMPLATE_INTRO}\n#{template}" if action.injects_type_template? && template

        Messages.new(system:, user: content)
      end
    end
  end
end
