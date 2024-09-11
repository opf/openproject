# --copyright
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
# ++

require_relative "../../lib_static/open_project/feature_decisions"

# Add feature flags here via e.g.
#
#   OpenProject::FeatureDecisions.add :some_flag
#
# If the feature to be flag-guarded stems from a module, add an initializer
# to that module's engine:
#
#   initializer 'the_engine.feature_decisions' do
#     OpenProject::FeatureDecisions.add :some_flag
#   end
OpenProject::FeatureDecisions.add :percent_complete_edition,
                                  description: "Allow edition of % Complete in work-based progress calculation mode. " \
                                               "Will be enabled by default in OpenProject 15.0. " \
                                               "See work package #52233 for more details."

OpenProject::FeatureDecisions.add :meeting_updated_notification,
                                  description: "Allow flash messages to notify users about concurrent meeting edits. " \
                                               "See work package #54744 for more details."
