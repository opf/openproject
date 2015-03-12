#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'reform'
require 'reform/form/active_model/model_validations'

module API
  module Contracts
    class ModelContract < Reform::Contract
      def self.writable_attributes
        @writable_attributes ||= []
      end

      def self.attribute_validations
        @attribute_validations ||= []
      end

      def self.attribute(*attributes, &block)
        writable_attributes.concat attributes.map(&:to_s)
        if block
          attribute_validations << block
        end
      end

      validate :readonly_attributes_unchanged
      validate :run_attribute_validations

      private

      def readonly_attributes_unchanged
        changed_attributes = model.changed - self.class.writable_attributes

        errors.add :error_readonly, changed_attributes unless changed_attributes.empty?
      end

      def run_attribute_validations
        self.class.attribute_validations.each { |validation| instance_exec(&validation) }
      end
    end
  end
end
