#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require 'redcloth3'

module RedCloth3Patch
  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      alias_method_chain :block_textile_prefix, :numbering
    end
  end

  module InstanceMethods
    private

    def block_textile_prefix_with_numbering(text)
      text.replace(prepend_number_to_heading(text))

      block_textile_prefix_without_numbering(text)
    end

    HEADING = /^h(\d)\.(.*)$/ unless defined? HEADING
    NUMBERED_HEADING = /^h(\d)#\.(.*)$/ unless defined? NUMBERED_HEADING

    def prepend_number_to_heading(text)
      if text =~ NUMBERED_HEADING
        level = $1.to_i

        number = get_next_number_or_start_new_numbering level

        new_text = "h#{level}. #{number}#{$2}"
      elsif text =~ HEADING
        reset_numbering
      end

      new_text.nil? ? text : new_text
    end

    def get_next_number_or_start_new_numbering(level)
      begin
        number = get_number_for_level level
      rescue ArgumentError
        reset_numbering
        number = get_number_for_level level
      end

      number
    end

    def get_number_for_level(level)
      @numbering_provider ||= Redcloth3::NumberingStack.new level

      @numbering_provider.get_next_numbering_for_level level
    end

    def reset_numbering
      @numbering_provider = nil
    end
  end
end

RedCloth3.send(:include, RedCloth3Patch)

module Redcloth3
  class NumberingStack
    def initialize(level)
      @stack = []
      @init_level = level ? level.to_i : 1
    end

    def get_next_numbering_for_level(level)
      internal_level = map_external_to_internal_level level

      increase_numbering_for_level internal_level

      current_numbering
    end

    private

    def increase_numbering_for_level(level)
      if @stack[level].nil?
        @stack[level] = 1
        fill_nil_levels_with_zero
      else
        @stack[level] += 1
        reset_higher_levels_than level
      end

      @stack[level]
    end

    def reset_higher_levels_than(level)
      @stack = @stack.slice! 0, level + 1
    end

    def current_numbering
      @stack.join('.') + '.'
    end

    def map_external_to_internal_level(level)
      if level.to_i < @init_level
        raise ArgumentError, 'Current level lower than initial level'
      end
      level.to_i - @init_level
    end

    def fill_nil_levels_with_zero
      @stack.map! { |e| e.nil? ? 0 : e }
    end
  end
end
