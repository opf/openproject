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

class WorkPackageRelationsTab::AddWorkPackageHierarchyDialogComponent < ApplicationComponent
  include ApplicationHelper
  include OpTurbo::Streamable
  include OpPrimer::ComponentHelpers

  I18N_NAMESPACE = "work_package_relations_tab"
  DIALOG_ID = "add-work-package-hierarchy-dialog"
  FORM_ID = "add-work-package-hierarchy-form"

  attr_reader :work_package, :relation_type

  def initialize(work_package:, relation_type:)
    super()

    @work_package = work_package
    @relation_type = relation_type
  end

  private

  def dialog_title
    hierarchy_label = t("#{I18N_NAMESPACE}.relations.label_#{relation_type}_singular")
    t("#{I18N_NAMESPACE}.label_add_x", x: hierarchy_label)
  end

  def body_classes
    "Overlay-body_autocomplete_height"
  end
end
