#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module Storages::Peripherals
  module ServiceResultRefinements
    refine ServiceResult do
      def match(on_success:, on_failure:)
        if success?
          on_success.call(result)
        else
          on_failure.call(errors)
        end
      end

      def bind
        return self if failure?

        yield result
      end
    end

    refine(ServiceResult.singleton_class) do
      def chain(initial:, steps:) # rubocop:disable Metrics/AbcSize
        unless initial.instance_of?(ServiceResult)
          raise TypeError, "Expected a #{ServiceResult.name.split('::').last}, got #{initial.class.name}."
        end

        unless steps.instance_of?(Array) && steps.all? { |step| step.instance_of?(Method) }
          raise TypeError, "Expected an Array of Method, got #{steps.class.name}."
        end

        steps.map(&:to_proc).reduce(initial) do |state, method|
          state.bind { |value| method.call(value) }
        end
      end
    end
  end
end
