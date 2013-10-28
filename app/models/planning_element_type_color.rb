#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class PlanningElementTypeColor < ActiveRecord::Base
  unloadable

  self.table_name = 'planning_element_type_colors'

  acts_as_list
  default_scope :order => 'position ASC'

  has_many :planning_element_types, :class_name  => 'Type',
                                    :foreign_key => 'color_id',
                                    :dependent   => :nullify

  include ActiveModel::ForbiddenAttributesProtection

  before_validation :normalize_hexcode

  validates_presence_of :name, :hexcode

  validates_length_of :name, :maximum => 255, :unless => lambda { |e| e.name.blank? }
  validates_format_of :hexcode, :with => /\A#[0-9A-F]{6}\z/, :unless => lambda { |e| e.hexcode.blank? }

  def self.ms_project_colors
    # Colors should be limited to the ones in MS Project.
    # http://msdn.microsoft.com/en-us/library/ff862872.aspx
    [
      self.find_or_initialize_by_name_and_hexcode('pjBlack',   '#000000'),
      self.find_or_initialize_by_name_and_hexcode('pjRed',     '#FF0013'),
      self.find_or_initialize_by_name_and_hexcode('pjYellow',  '#FEFE56'),
      self.find_or_initialize_by_name_and_hexcode('pjLime',    '#82FFA1'),
      self.find_or_initialize_by_name_and_hexcode('pjAqua',    '#C0DDFC'),
      self.find_or_initialize_by_name_and_hexcode('pjBlue',    '#1E16F4'),
      self.find_or_initialize_by_name_and_hexcode('pjFuchsia', '#FF7FF7'),
      self.find_or_initialize_by_name_and_hexcode('pjWhite',   '#FFFFFF'),
      self.find_or_initialize_by_name_and_hexcode('pjMaroon',  '#850005'),
      self.find_or_initialize_by_name_and_hexcode('pjGreen',   '#008025'),
      self.find_or_initialize_by_name_and_hexcode('pjOlive',   '#7F8027'),
      self.find_or_initialize_by_name_and_hexcode('pjNavy',    '#09067A'),
      self.find_or_initialize_by_name_and_hexcode('pjPurple',  '#86007B'),
      self.find_or_initialize_by_name_and_hexcode('pjTeal',    '#008180'),
      self.find_or_initialize_by_name_and_hexcode('pjGray',    '#808080'),
      self.find_or_initialize_by_name_and_hexcode('pjSilver',  '#BFBFBF')
    ]
  end

  def text_hexcode
    # 0.63 - Optimal threshold to switch between white and black text color
    #        determined by intensive user tests and expensive research
    #        activities.
    if Color::RGB::from_html(hexcode).to_hsl.brightness <= 0.63
      '#fff'
    else
      '#000'
    end
  end

  protected

  def normalize_hexcode
    if hexcode.present? and hexcode_changed?
      self.hexcode = hexcode.strip.upcase

      unless hexcode.starts_with? '#'
        self.hexcode = '#' + hexcode
      end

      if hexcode.size == 4  # =~ /#.../
        self.hexcode = hexcode.gsub(/([^#])/, '\1\1')
      end
    end
  end
end
