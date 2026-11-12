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

class ApplicationComponent < ViewComponent::Base
  prepend TranslationsOverride

  attr_reader :model, :options

  def initialize(model = nil, **options)
    super()
    @model = model if model
    @options = options
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end

  class << self
    ##
    # Generates a unique identifier suitable for use as an HTML `id` attribute
    # value. If passed a non-nil model instance, it will use the model's id to
    # generate the identifier (see {ActiveModel::Conversion#to_param}).
    # Otherwise, it will generate an identifier with random numbers.
    #
    # @see ActiveModel::Conversion#to_param
    #
    # @param [ActiveModel::Model] model an optional model instance.
    # @param [String] base_name a prefix for the unique identifier.
    # @return [String] a unique identifier.
    def generate_id(model = nil, base_name: name.demodulize.underscore.dasherize)
      "#{base_name}-#{model&.to_param || SecureRandom.uuid}"
    end

    ##
    # Defines options for this cell which can be used within the cell's template.
    # Options are passed to the cell during the render call.
    #
    # @param names [Array<String> | Hash<String, Any>] Either a list of names for options whose
    #                                                  default value is empty or a hash mapping
    #                                                  option names to default values.
    def options(*names)
      default_values = {}

      if names.size == 1 && names.first.is_a?(Hash)
        default_values = names.first
        names = default_values.keys
      end

      names.each do |name|
        define_method(name) do
          options.has_key?(name) ? options[name] : default_values[name]
        end
      end
    end

    def property(*names)
      delegate *names, to: :model
    end
  end
end
