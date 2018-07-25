#-- encoding: UTF-8
#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

class MyProjectsOverview < ActiveRecord::Base
  after_initialize :initialize_default_values

  DEFAULTS = {
    "left" => %w(project_description project_details work_package_tracking),
    "right" => %w(members news_latest),
    "top" => [],
    "hidden" => []
  }.freeze

  def initialize_default_values
    # attributes() creates a copy every time it is called, so better not use it in a loop
    # (this is also why we send the default-values instead of just setting it on attributes)
    attr = attributes

    DEFAULTS.each_key do |attribute_name|
      # mysql and postgres handle serialized arrays differently: This check initializes the defaults for both cases -
      # this especially deals properly with the case where [] is written into the db and re-read ( which
      # is not properly handled by a .blank?- check !!!)
      send("#{attribute_name}=", DEFAULTS[attribute_name]) if attr[attribute_name].nil? || attr[attribute_name] == ""
    end
  end

  serialize :top
  serialize :left
  serialize :right
  serialize :hidden
  belongs_to :project

  validate :fields_are_arrays

  acts_as_attachable delete_permission: :edit_project,
                     view_permission: :view_project,
                     add_permission: :edit_project

  def fields_are_arrays
    Array === top && Array === left && Array === right && Array === hidden
  end

  def save_custom_element(name, title, new_content)
    el = custom_elements.detect { |x| x.first == name}
    return false unless el
    return false unless title && new_content

    el[1] = title
    el[2] = new_content
    save
  end

  def new_custom_element
    idx = custom_elements.any? ? custom_elements.sort.last.first.next : "a"
    [idx, l(:label_custom_element), "### #{I18n.t(:info_custom_text)}"]
  end

  def elements
    top + left + right + hidden
  end

  def custom_elements
    elements.select { |x| x.respond_to? :to_ary }
  end
end
