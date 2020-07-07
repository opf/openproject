#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

##
# Dependent service to be executed under the BaseServices::Copy service
module Copy
  class Dependency
    attr_reader :source,
                :target,
                :user,
                :result


    ##
    # Identifier of this dependency to include/exclude
    def self.identifier
      name.demodulize.gsub('DependentService', '').underscore
    end

    def initialize(source:, target:, user:)
      @source = source
      @target = target
      @user = user
      # Create a result with an empty error set
      # that we can merge! so that not the target.errors object is reused.
      @result = ServiceResult.new(result: target, success: true, errors: ActiveModel::Errors.new(target))
    end

    def call(params:, state:)
      return result if skip?(params)

      begin
        perform(params: params, state: state)
      rescue StandardError => e
        Rails.logger.error { "Failed to copy dependency #{self.class.name}: #{e.message}" }
        result.success = false
        result.errors.add(self.class.identifier, :could_not_be_copied)
      end

      result
    end


    protected

    ##
    # Merge some other model's errors with the result errors
    def add_error!(model, errors)
      result.errors.add(:base, "#{model.class.model_name.human} '#{model}': #{errors.full_messages.join(". ")}")
    end

    ##
    # Whether this entire dependency should be skipped
    def skip?(params)
      skip_dependency?(params, self.class.identifier)
    end

    ##
    # Whether to skip the given key.
    # Useful when copying nested dependencies
    def skip_dependency?(params, name)
      return false unless params[:only].present?

      !params[:only].any? { |key| key.to_s == name.to_s }
    end

    def perform(params:, state:)
      raise NotImplementedError
    end
  end
end
