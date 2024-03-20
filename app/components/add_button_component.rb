# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++
#

class AddButtonComponent < ApplicationComponent
  options :current_project

  def render?
    raise 'Implement the conditions for which the component should render or not'
  end

  def dynamic_path
    raise "Implement the path for this component's href"
  end

  def id
    raise "Implement the id for this component"
  end

  def li_css_class
    'toolbar-item'
  end

  def title
    accessibility_label_text
  end

  def label
    content_tag(:span,
                label_text,
                class: 'button--text')
  end

  def aria_label
    accessibility_label_text
  end

  def accessibility_label_text
    raise "Specify the aria label and title text to be used for this component"
  end

  def label_text
    raise "Specify the label text to be used for this component"
  end

  def link_css_class
    'button -alt-highlight'
  end

  def icon
    helpers.op_icon('button--icon icon-add')
  end
end
