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

class WorkPackageRelationsTab::AddWorkPackageHierarchyFormComponent < ApplicationComponent
  include ApplicationHelper
  include OpTurbo::Streamable
  include OpPrimer::ComponentHelpers

  DIALOG_ID = "add-work-package-hierarchy-dialog"
  FORM_ID = "add-work-package-hierarchy-form"
  ID_FIELD_TEST_SELECTOR = "work-package-hierarchy-form-id"
  I18N_NAMESPACE = "work_package_relations_tab"

  attr_reader :work_package, :relation_type, :related, :base_errors

  def initialize(work_package:, relation_type:, related: nil, base_errors: nil)
    super()

    @work_package = work_package
    @relation_type = relation_type
    @related = related.presence || WorkPackage.new
    @base_errors = base_errors || []
  end

  def submit_url_options
    { method: :post,
      url: work_package_hierarchy_relations_path(work_package, relation_type:) }
  end
end
