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

# rubocop:disable Rails/RakeEnvironment
namespace :copyright do
  namespace :authors do
    desc "Shows contributors of a repository"
    task :show, :path do |_task, args|
      contribution_periods = contribution_periods_of_repository(args[:path])
      formatted_periods = format_contribution_periods(contribution_periods)

      show_contribution_periods(formatted_periods)
    end

    private

    def contributions_of_repository(path)
      contribution_info = Data.define(:author, :date)

      path = "." if path.nil?
      log = `git --git-dir #{path}/.git log --date=short --pretty=format:"%ad %aN"`

      log.scan(/^(?<date>\d\d\d\d-\d\d-\d\d) (?<author>.*)$/).map do |m|
        contribution_info.new(m[1], Date.parse(m[0]))
      end
    end

    def contribution_periods_of_repository(path)
      contribution_period = Data.define(:author, :begin, :end)

      contribution_periods = contributions_of_repository(path)
        .group_by(&:author).map do |author, author_contributions|
          first, last = author_contributions.map { |c| c.date.year }.minmax

          contribution_period.new(author, first, last)
        end

      contribution_periods
        .sort_by { |c| [c.end, c.begin] }
        .reverse
    end

    def format_contribution_periods(contribution_periods)
      contribution_periods.each_with_object({}) do |c, h|
        date = c.begin == c.end ? c.begin.to_s : "#{c.begin} - #{c.end}"
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
# rubocop:enable Rails/RakeEnvironment
