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

class WorkPackages::ActivitiesTab::InternalCommentMentionsSanitizer
  def self.sanitize(work_package, comment)
    new(work_package, comment).call
  end

  def initialize(work_package, comment)
    @work_package = work_package
    @comment = comment
  end

  def call
    return "" if comment.blank?

    convert_unmentionable_principals_to_plain_text
    CGI.unescapeHTML(parser.to_html)
  end

  private

  attr_reader :work_package, :comment

  def convert_unmentionable_principals_to_plain_text
    mentionable_principals_ids = mentionable_principals.pluck(:id)

    parser.css("mention").each do |mention|
      unless mentionable_principals_ids.include?(mention["data-id"].to_i)
        mention.replace(mention.content)
      end
    end
  end

  def parser
    @parser ||= Nokogiri::HTML.fragment(comment)
  end

  def mentionable_principals
    @mentionable_principals ||= Queries::Principals::PrincipalQuery.new(user: User.current)
      .where(:internal_mentionable_on_work_package, "=", [work_package.id])
      .where(:status, "!", [Principal.statuses[:locked]])
      .where(:type, "=", %w[User Group])
      .results
  end
end
