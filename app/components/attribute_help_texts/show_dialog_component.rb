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

class AttributeHelpTexts::ShowDialogComponent < ApplicationComponent
  include OpTurbo::Streamable

  attr_reader :attribute_help_text, :current_user, :dialog_id

  def initialize(attribute_help_text:, current_user: User.current, **system_arguments)
    super

    @attribute_help_text = attribute_help_text
    @current_user = current_user

    @dialog_id = dom_id(@attribute_help_text, :dialog)
    @system_arguments = system_arguments
    @system_arguments[:id] = dialog_id
    @system_arguments[:title] = @attribute_help_text.attribute_field_name
  end

  private

  def allowed_to_edit? = current_user.allowed_globally?(:edit_attribute_help_texts)

  def edit_button_href = url_helpers.edit_attribute_help_text_path(attribute_help_text)

  def resource_representer
    ::API::V3::HelpTexts::HelpTextRepresenter.new(attribute_help_text, current_user:, embed_links: false)
  end
end
