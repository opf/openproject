# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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

module GitlabIntegration
  GitlabStatus = Data.define(:code, :color, :icon, :for_type) do
    private_class_method :new

    def id = code&.to_s

    def value = code&.to_s

    def type = for_type&.to_s

    def self.issue_status(code:, color:, icon:)
      new(code:, color:, icon:, for_type: :issue)
    end

    def self.merge_request_status(code:, color:, icon:)
      new(code:, color:, icon:, for_type: :merge_request)
    end

    def self.pipeline_status(code:, color:, icon:)
      new(code:, color:, icon:, for_type: :pipeline)
    end
  end
end
