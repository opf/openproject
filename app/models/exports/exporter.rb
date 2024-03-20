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
module Exports
  class Exporter
    include Redmine::I18n
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper

    attr_accessor :object,
                  :options,
                  :current_user

    class_attribute :model

    def initialize(object, options = {})
      self.object = object
      self.options = options
      self.current_user = options.fetch(:current_user) { User.current }
    end

    def self.key
      name.demodulize.underscore.to_sym
    end

    # Remove characters that could cause problems on popular OSses
    def sane_filename(name)
      parts = name.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

      parts.map! { |s| s.gsub /[^a-z0-9-]+/i, '_' }

      parts.join '.'
    end

    # Run the export, yielding the result of the render output
    def export!
      raise NotImplementedError
    end

    protected

    def formatter_for(attribute, export_format)
      ::Exports::Register.formatter_for(model, attribute, export_format)
    end

    def format_attribute(object, attribute, export_format, **)
      formatter = formatter_for(attribute, export_format)
      formatter.format(object, **)
    end
  end
end
