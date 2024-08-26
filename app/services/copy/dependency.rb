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

##
# Dependent service to be executed under the BaseServices::Copy service
module Copy
  class Dependency < ::BaseServices::BaseCallable
    attr_reader :source,
                :target,
                :user,
                :result

    ##
    # Identifier of this dependency to include/exclude
    def self.identifier
      name.demodulize.gsub("DependentService", "").underscore
    end

    ##
    # Localizable human name used in errors
    def self.human_name
      identifier.capitalize
    end

    ##
    # Dependencies the current dependency itself supports.
    # The most common case for this are attachment services.
    def self.copy_dependencies
      []
    end

    def initialize(source:, target:, user:)
      @source = source
      @target = target
      @user = user
      # Create a result with an empty error set
      # that we can merge! so that not the target.errors object is reused.
      @result = ServiceResult.success(result: target, errors: ActiveModel::Errors.new(target))
    end

    protected

    ##
    # Merge some other model's errors with the result errors
    def add_error!(model, errors, model_name: human_model_name(model))
      result.errors.add(:base, "#{model_name}: #{error_messages(errors)}")
    end

    def human_model_name(model)
      "#{model.class.model_name.human} '#{model}'"
    end

    def error_messages(errors)
      errors.full_messages.join(". ")
    end

    def perform(params:)
      begin
        copy_dependency(params:)
      rescue StandardError => e
        Rails.logger.error { "Failed to copy dependency #{self.class.identifier}: #{e.message}" }
        ::OpenProject.logger.error e

        result.success = false
        result.errors.add(:base, :could_not_be_copied, dependency: self.class.human_name)
      end

      result
    end

    def copy_dependency(params:)
      raise NotImplementedError
    end
  end
end
