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

# Copies one variant's workflows onto other variants.
class Workflows::Copies::FromVariantsController < ApplicationController
  include ::WorkPackageTypes::ConfiguredInScope
  include OpTurbo::ComponentStream

  before_action :set_source_variant
  before_action :set_target_variants

  def create
    if @source_variant.nil?
      render_flash_message_via_turbo_stream(
        message: I18n.t(:error_workflow_copy_source),
        scheme: :danger
      )
      @turbo_status = :unprocessable_entity
    elsif @target_variants.blank?
      render_flash_message_via_turbo_stream(
        message: I18n.t(:error_workflow_copy_target),
        scheme: :danger
      )
      @turbo_status = :unprocessable_entity
    else
      Workflow.copy(@source_variant, nil, @target_variants, Workflow.eligible_roles)

      target = @target_variants.first
      redirect_to edit_type_workflow_path(**target.path_args),
                  notice: t(".notice", count: @target_variants.size, type_name: target.display_name)
      return
    end

    respond_with_turbo_streams
  end

  private

  def set_source_variant
    @source_variant = ::TypeVariant.find_by(id: params[:variant_id])
  end

  # The targets are written to, so scope them against the source rather than trusting the ids.
  def set_target_variants
    return @target_variants = ::TypeVariant.none if @source_variant.nil?

    @target_variants = ::TypeVariant.available_in(@source_variant.project)
                                    .where(id: params[:target_variant_ids])
  end
end
