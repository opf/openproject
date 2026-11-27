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

# Multi_json issue #208 https://github.com/intridea/multi_json/issues/208
# produces a `NoMethodError` with some tests like
# modules/bim/spec/requests/api/bcf/v2_1/viewpoints_api_spec.rb:277 where grape
# is calling multi_json with a specific adapter. It will fail if it is the first
# test executed.
#
# Calling this will prevent the error from happening
MultiJSON::OptionsCache.reset

# This file can be removed once the issue has been fixed and released in a new
# version of multi_json gem (issue exists in 1.15.0)
