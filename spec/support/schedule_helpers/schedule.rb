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

module ScheduleHelpers
  class Schedule
    def initialize(work_packages, follows_relations)
      @work_packages = work_packages
      @follows_relations = follows_relations
    end

    def work_package(name)
      name = normalize_name(name)
      @work_packages[name]
    end

    def follows_relation(from:, to:)
      from = normalize_name(from)
      to = normalize_name(to)
      @follows_relations[from:, to:]
    end

    def monday
      Date.current.next_occurring(:monday)
    end

    %i[tuesday wednesday thursday friday saturday sunday].each do |day_name|
      define_method(day_name) { monday.next_occurring(day_name) }
    end

    private

    def normalize_name(name)
      symbolic_name = name.to_sym
      return symbolic_name if @work_packages.has_key?(symbolic_name)

      spell_checker = DidYouMean::SpellChecker.new(dictionary: @work_packages.keys.map(&:to_s))
      suggestions = spell_checker.correct(name).map(&:inspect).join(" ")
      did_you_mean = " Did you mean #{suggestions} instead?" if suggestions.present?
      raise "No work package with name #{name.inspect} in schedule.#{did_you_mean}"
    end
  end
end
