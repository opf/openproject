#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

namespace :copyright do
  namespace :authors do
    desc 'Shows contributors of a repository'
    task :show, :arg1 do |_task, args|
      contribution_periods = contribution_periods_of_repository(args[:arg1])
      formatted_periods = format_contribution_periods(contribution_periods)

      show_contribution_periods(formatted_periods)
    end

    private

    CONTRIBUTION = Struct.new(:author, :date)
    CONTRIBUTION_PERIOD = Struct.new(:author, :begin, :end)

    CONTRIBUTION_REGEX = /^(?<date>\d\d\d\d-\d\d-\d\d) (?<author>.*)$/

    def contribution_periods_of_repository(path)
      contributions = []
      contribution_periods = []
      path = '.' if path.nil?
      log = `git --git-dir #{path}/.git log --date=short --pretty=format:"%ad %aN"`

      log.scan(CONTRIBUTION_REGEX).each do |m|
        contributions << CONTRIBUTION.new(m[1], Date.parse(m[0]))
      end

      authors = contributions.collect(&:author).uniq

      authors.each do |a|
        first, last = contributions.select { |c| c.author == a }
                      .minmax { |a, b| a.date <=> b.date }
        contribution_periods << CONTRIBUTION_PERIOD.new(a, first.date.year, last.date.year)
      end

      contribution_periods.sort_by { |c| [c.end, c.begin] }.reverse
    end

    def format_contribution_periods(contribution_periods)
      contribution_periods.each_with_object({}) do |c, h|
        date = (c.begin == c.end) ? c.begin.to_s : "#{c.begin} - #{c.end}"
        h[date] = [] unless h.has_key? date
        h[date] << c.author
      end
    end

    def show_contribution_periods(formatted_periods)
      formatted_periods.each_pair do |date, authors|
        puts "#{date} #{authors.join(', ')}"
      end
    end
  end
end
