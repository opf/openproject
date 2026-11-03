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

# Stands in for the WorkPackageTypes::ConfiguredInScope controllers a variant screen is
# rendered by, which expose the scope to their views.
class VariantScopeTestController < ApplicationController
  helper_method :variant_scope_project

  attr_accessor :variant_scope_project
end

# Renders components as a variant screen does, in administration unless the example names a
# project with `let(:variant_scope_project)`.
RSpec.shared_context "with variant scope" do
  let(:variant_scope_project) { nil }

  def vc_test_controller_class = VariantScopeTestController

  before { vc_test_controller.variant_scope_project = variant_scope_project }
end
