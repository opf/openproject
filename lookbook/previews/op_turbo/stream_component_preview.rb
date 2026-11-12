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

module OpTurbo
  # @logical_path OpenProject/OpTurbo
  class StreamComponentPreview < Lookbook::Preview
    # Renders a turbo-stream tag with given action and target
    # @param _action select { choices: [append, prepend, replace, update, remove, before, after] }
    # @param target text
    def default(_action: "append", target: "model_id")
      template = template_example_from_action(_action, target)
      render_with_template(locals: { template:, action: _action, target: })
    end

    private

    def template_example_from_action(action, target)
      <<~HTML
        <div id="#{target}">
          This div will #{action} to the element with the DOM ID "#{target}".
        </div>
      HTML
    end
  end
end
