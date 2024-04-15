#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module BaseServices
  class Copy < ::BaseServices::Write
    alias_attribute(:source, :model)

    ##
    # dependent services to copy associations
    def self.copy_dependencies
      []
    end

    ##
    # collect copyable associated modules
    def self.copyable_dependencies
      copy_dependencies
        .flat_map { |dependency| [dependency] + dependency.copy_dependencies }
        .map do |service_cls|
        {
          identifier: service_cls.identifier,
          name_source: -> { service_cls.human_name },
          count_source: ->(source, user) do
            service_cls
              .new(source:, target: nil, user:)
              .source_count
          end
        }
      end
    end

    def initialize(user:, source: nil, model: nil, contract_class: nil, contract_options: {})
      self.source = source || model
      raise ArgumentError, "Missing source object" if self.source.nil?

      contract_options[:copy_source] = self.source
      super(user:, contract_class:, contract_options:)
    end

    def call(params)
      prepare_state(params)

      super
    end

    def persist(call)
      # Return only the unsaved copy
      return call if params[:attributes_only]

      super.tap do |super_call|
        copy_instance = super_call.result
        self.class.copy_dependencies.each do |service_cls|
          next if skip_dependency?(params, service_cls)

          super_call.merge! call_dependent_service(service_cls, target: copy_instance, params:),
                            without_success: true
        end
      end
    end

    def after_perform(call)
      return call if params[:attributes_only]

      super
    end

    protected

    ##
    # Should the dependency be skipped for this service run?
    def skip_dependency?(_params, _dependency_cls)
      false
    end

    ##
    # Sets up a state object that gets
    # passed around to all service calls from here
    #
    # Note that for dependent copy services to be called
    # this will already be present.
    def prepare_state(_params)
      # Retain the source project itself
      state.source = source
    end

    ##
    # Calls a dependent service with the source and copy instance
    def call_dependent_service(service_cls, target:, params:)
      service_cls
        .new(source:, target:, user:)
        .with_state(state)
        .call(params:)
    end

    def instance(_params)
      source.class.new
    end

    def default_contract_class
      "#{namespace}::CopyContract".constantize
    end
  end
end
