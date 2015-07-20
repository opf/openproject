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
module OpenProject
  module Acts
    module Countable
      ##
      # Register this model to be countable for the given identifier.
      #
      # @params [Symbol] identifier A count identifier used to uniquely identify a countable
      #                  instance.
      # @params [Hash] options May contain the following options:
      # -+:countable:+    A hash providing several options to gather counts from this model:
      #     - +Symbol+: Calls the method :symbol which should return an integer count result.
      #     - +Proc+:   Calls the proc to gather an integral count result.
      #     - +Array+:  Calls +get_count(:identifier)+ on the given N *associatons*
      #                 and returns a hash with N keys of the form
      #                 { label: <integer or hash>, [ .. label: <integer or hash>, ]
      #                   total: sum of all association values
      #                 }
      # - +:collection+:  By default, +count_for(:identifier)+ is added to this instance.
      #                   When the association is used as a relation, it is added as a class method
      #                   instead.
      # - +:label+:       Set the label to return for this assocation or countable result.
      #                   Defaults to the assocation name.
      #
      def acts_as_countable(identifier, options = {})
        cattr_accessor :countable_options
        self.countable_options ||= {}
        self.countable_options[identifier] = options

        ##
        # Allow to run on both collections of associated models
        # (will be run on AR::Relation object, thus has only access to class methods),
        # otherwise, make it available as an instance method.
        if options[:collection]
          extend CountMethod
        else
          include CountMethod
        end
      end
    end

    module CountMethod
      ##
      # Count the defined associations for the given identifier.
      # Will recursively descend into assocations to compute an aggregated count
      # of whatever the association members define as countable for this identifier.
      #
      # Example:
      # +Project#count_for(:required_project_storage)+ will return:
      #   - +count_for(:required_project_storage)+ of all associations defined in +:countable+.
      # Assume Project has defined +:countable+ to contain +:work_packages+ and +:repository*.
      #
      # Then, +count_for+ will be called on the work_packages relation and repository instance
      # and returned is a hash of the type:
      #
      # { ':label defined by work_packages': { association: count, total: 1234 },
      #   ':label defined by repository':    1000,
      #   total: 2234
      # }
      #
      # @returns the count as a hash of association counts and the total count.
      # @returns the label defined on this node or nil, if not defined.
      def count_for(identifier)
        options = self.countable_options[identifier]
        countable = options[:countable]

        count = count_descend(identifier, countable)

        # TODO: what should we do when children are unable to provide a count
        # for this instance (e.g., due to asynchronously retrieved counts).
        # We may provide an option to allow this replacement, or to raise
        # when nil is encountered.
        count = 0 if count.nil?

        [count, options[:label]]
      end

      private

      ##
      # Return the aggregated count of all children in the
      # +countable+ array.
      #
      # Example:
      # Project:
      #   acts_as_countable :required_project_storage,
      #                     countable: [ :work_packages , :repository ]
      #
      # +project.required_project_storage+ will call
      # +determine_count(:required_project_storage)+ on the assocations
      # :work_packages (collection) and :repository (single relation)
      def aggregate_count(identifier, countable)
        count = {}
        count[:total] = countable.inject(0) do |agg, association|
          target = send(association)
          if target.nil?
            agg
          else
            subcount, subtotal, label = count_member(target, identifier)
            count[label.presence || target] = subcount
            agg + subtotal
          end
        end

        count
      end

      ##
      # Retrieve recursive member count for the given association target.
      # This will either be an integral value, or hash containing other associations
      # and a subtotal value.
      def count_member(target, identifier)
        subcount, label = target.send(:count_for, identifier)

        if subcount.is_a? Hash
          total = subcount[:total]
        else
          total = subcount
        end

        [subcount, total, label]
      end

      ##
      # Determines the kind of countable given to this model
      # and retrieves the result by extracting it from this model itself,
      # or by descending into children
      def count_descend(identifier, countable)
        case countable
        when Array
          aggregate_count(identifier, countable)
        when Proc
          instance_exec &countable
        when Symbol
          send countable
        else
          raise ArgumentError.new 'Invalid countable passed to acts_as_countable.'
        end
      end
    end
  end
end
