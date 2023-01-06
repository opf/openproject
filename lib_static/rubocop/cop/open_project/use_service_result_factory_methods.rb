#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module RuboCop::Cop::OpenProject
  # # bad
  # ServiceResult.new(success: true, result: 'result')
  # ServiceResult.new(success: false, errors: ['error'])
  #
  # # good
  # ServiceResult.success(result: 'result')
  # ServiceResult.failure(errors: ['error'])
  # ServiceResult.new(success: some_value)
  # ServiceResult.new(**kwargs)
  class UseServiceResultFactoryMethods < RuboCop::Cop::Base
    extend RuboCop::Cop::AutoCorrector

    MSG = 'Use ServiceResult.%<factory_method>s(...) instead of ServiceResult.new(success: %<success_value>s, ...).'.freeze
    MSG_IMPLICIT_FAILURE = 'Use ServiceResult.failure instead of ServiceResult.new.'.freeze

    def_node_matcher :service_result_constructor?, <<~PATTERN
      (send
        $(const nil? :ServiceResult) :new
        ...
      )
    PATTERN

    def_node_matcher :constructor_with_explicit_success_arg, <<~PATTERN
      (send
        (const nil? :ServiceResult) :new
        (hash
          <
            $(pair (sym :success) ({true | false}))
            ...
          >
        )
      )
    PATTERN

    def on_send(node)
      return unless service_result_constructor?(node)

      if success_argument_present?(node)
        add_offense_if_explicit_success_argument(node)
      elsif success_argument_possibly_present?(node)
        return # rubocop:disable Style/RedundantReturn
      else
        add_offense_for_implicit_failure(node)
      end
    end

    private

    def success_argument_present?(node)
      hash_argument = node.arguments.find(&:hash_type?)
      return false unless hash_argument

      hash_argument.keys.any? { |key| key.sym_type? && key.value == :success }
    end

    def success_argument_possibly_present?(node)
      return true if node.arguments.find(&:forwarded_args_type?)

      hash_argument = node.arguments.find(&:hash_type?)
      return false unless hash_argument

      hash_argument.children.any?(&:kwsplat_type?)
    end

    def add_offense_if_explicit_success_argument(node)
      constructor_with_explicit_success_arg(node) do |success_argument|
        message = format(MSG, success_value: success_value(success_argument),
                              factory_method: factory_method(success_argument))
        add_offense(success_argument, message:) do |corrector|
          corrector.replace(node.loc.selector, factory_method(success_argument))
          corrector.remove(removal_range(node, success_argument))
        end
      end
    end

    def add_offense_for_implicit_failure(node)
      add_offense(node.loc.selector, message: MSG_IMPLICIT_FAILURE) do |corrector|
        corrector.replace(node.loc.selector, 'failure')
      end
    end

    def success_value(success_argument)
      success_argument.value.source
    end

    def factory_method(success_argument)
      success_argument.value.source == 'true' ? 'success' : 'failure'
    end

    def removal_range(node, success_argument)
      if sole_argument?(success_argument)
        all_parameters_range(node)
      else
        success_parameter_range(success_argument)
      end
    end

    def sole_argument?(arg)
      arg.parent.loc.expression == arg.loc.expression
    end

    def all_parameters_range(node)
      node.loc.selector.end.join(node.loc.expression.end)
    end

    # rubocop:disable Metrics/AbcSize
    def success_parameter_range(success_argument)
      if success_argument.left_sibling
        success_argument.left_sibling.loc.expression.end.join(success_argument.loc.expression.end)
      else
        success_argument.loc.expression.begin.join(success_argument.right_sibling.loc.expression.begin)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
