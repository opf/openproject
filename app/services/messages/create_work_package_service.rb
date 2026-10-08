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

module Messages
  class CreateWorkPackageService
    attr_reader :user, :message

    def initialize(user:, message:)
      @user = user
      @message = message
    end

    def build_work_package(params: {}) # rubocop:disable Metrics/AbcSize
      work_package = WorkPackage.new(project:)

      WorkPackages::SetAttributesService
        .new(model: work_package, user:, contract_class: WorkPackages::CreateContract)
        .call(prefill(work_package).merge(params.to_h.symbolize_keys))
        .result
        .tap do |built|
          built.errors.clear
          built.custom_values.each { it.errors.clear }
        end
    end

    def call(work_package_params:) # rubocop:disable Metrics/AbcSize
      result = nil

      ApplicationRecord.transaction do
        result = WorkPackages::CreateService.new(user:).call(work_package_params.to_h.symbolize_keys.merge(project:))
        raise ActiveRecord::Rollback if result.failure?

        Journals::CreateService.new(result.result, user).call(cause: Journal::CausedByForumMessage.new(message))
        MessageWorkPackage.create!(message:, work_package: result.result)
      end

      result
    end

    private

    def project = message.project

    def prefill(work_package)
      {
        type: WorkPackages::CreateContract.new(work_package, user).assignable_types.first,
        subject: message.root.subject,
        description: message.content
      }
    end
  end
end
