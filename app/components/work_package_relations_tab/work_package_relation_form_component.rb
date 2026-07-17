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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackageRelationsTab::WorkPackageRelationFormComponent < ApplicationComponent
  include ApplicationHelper
  include OpTurbo::Streamable
  include OpPrimer::ComponentHelpers

  DIALOG_ID = "work-package-relation-dialog"
  FORM_ID = "work-package-relation-form"
  TO_ID_FIELD_TEST_SELECTOR = "work-package-relation-form-to-id"
  I18N_NAMESPACE = "work_package_relations_tab"

  def initialize(work_package:, relation:, base_errors: nil)
    super()

    @work_package = work_package
    @relation = relation
    @base_errors = base_errors
  end

  def related_work_package
    @related_work_package ||= begin
      # We cannot rely on the related WorkPackage being the "to",
      # depending on the relation it can also be "from"
      relation_to_matches_wp? ? @relation.from : @relation.to
    end
  end

  def displayable_field_value
    return nil if related_work_package.nil?

    "#{related_work_package.type.name.upcase} ##{related_work_package.id} - #{related_work_package.subject}"
  end

  def direction
    relation_to_matches_wp? ? :from_id : :to_id
  end

  def relation_to_matches_wp?
    @relation.to == @work_package
  end

  def submit_url_options
    if @relation.persisted?
      { method: :patch,
        url: work_package_relation_path(@work_package, @relation) }
    else
      { method: :post,
        url: work_package_relations_path(@work_package) }
    end
  end

  def show_lag?
    [Relation::TYPE_PRECEDES, Relation::TYPE_FOLLOWS].include?(@relation.relation_type)
  end
end
