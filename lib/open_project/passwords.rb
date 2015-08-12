# encoding: utf-8

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
  ##
  # Evaluate and generate passwords
  #
  module Passwords
    ##
    # Evaluates passwords and generates error messages for the evaluated
    # passwords based on password complexity settings like minimum password
    # length and other complexity rules.
    #
    module Evaluator
      RULES = { 'uppercase' => /.*[A-Z].*/u,
                'lowercase' => /.*[a-z].*/u,
                'special'   => /.*[^\da-zA-Z].*/u,
                'numeric'   => /.*\d.*/u }
      # Check whether password conforms to password complexity settings.
      # Checks complexity rules and password length.
      def self.conforming?(password)
        password_long_enough(password) and password_conforms_to_rules(password)
      end

      # Returns corresponding error messages if +password+ doesn't conform to
      # password complexity settings.
      def self.errors_for_password(password)
        errors = []
        unless password_conforms_to_rules(password)
          errors << rules_description
        end
        unless password_long_enough(password)
          errors << I18n.t(:too_short,
                           scope: [:activerecord, :errors, :messages],
                           count: OpenProject::Passwords::Evaluator.min_length)
        end
        errors
      end

      # Returns the names of known rules, e.g. ['uppercase'].
      def self.known_rules
        RULES.keys
      end

      # Returns the names of rules activated in settings.
      def self.active_rules
        Setting.password_active_rules
      end

      # Checks whether password adheres to complexity rules.
      # Does not check length.
      def self.password_conforms_to_rules(password)
        size_active_rules_adhered_by(password) >= min_adhered_rules
      end

      # Checks whether password matches minimum length specified in settings.
      def self.password_long_enough(password)
        password.length >= min_length
      end

      # Returns the minimum number of rules passwords must adhere to
      # to be accepted, as specified in settings and checked to be within
      # reasonable bounds (>= 0, <= number of active rules).
      def self.min_adhered_rules
        min = Setting.password_min_adhered_rules.to_i
        # ensure value is in interval [0, active_rules.size]
        [[0, min].max, active_rules.size].min
      end

      # Returns the minimum password length as specified in settings.
      def self.min_length
        Setting.password_min_length.to_i
      end

      # Returns a text describing the active password complexity rules,
      # the minimum number of rules to adhere to and the total number of rules.
      def self.rules_description
        return '' if min_adhered_rules == 0

        rules = active_rules_list.join(', ')
        rules_description_locale(rules)
      end

      # Returns a text describing the minimum length of a password.
      def self.min_length_description
        I18n.t(:text_caracters_minimum,
               count: OpenProject::Passwords::Evaluator.min_length)
      end

      private

      # Returns the number of active rules password adheres to.
      def self.size_active_rules_adhered_by(password)
        active_rules.count do |name|
          password =~ RULES[name] ? true : false
        end
      end

      # Return a collection with active rules
      def self.active_rules_list
        active_rules.map do |rule|
          I18n.t(rule.to_sym,
                 scope: [:activerecord, :errors, :models, :user, :attributes, :password])
        end
      end

      def self.rules_description_locale(rules)
        I18n.t(:weak,
               scope: [:activerecord, :errors, :models, :user, :attributes, :password],
               rules: rules,
               min_count: min_adhered_rules,
               all_count: active_rules.size)
      end
    end

    ##
    # Generates random passwords that conform to password complexity settings
    #
    module Generator
      RANDOM_PASSWORD_MIN_LENGTH = 15

      # Generates a random password with a minimum length of 15 or the minimum
      # password length, whichever is higher.
      # The generated password conforms to the active password rules.
      def self.random_password
        chars = ('a'..'z').to_a +
                ('A'..'Z').to_a +
                ('0'..'9').to_a +
                ['!', "\"", '#', '$', '%', '&', "'", '(', ')', '*', '+',
                 ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\',
                 ']', '^', '_', '`', '{', '|', '}', '~']

        begin
          password = ''
          length = [RANDOM_PASSWORD_MIN_LENGTH, Evaluator.min_length].max
          length.times { |_i| password << chars[SecureRandom.random_number(chars.size - 1)] }
        end while not Evaluator.conforming? password
        password
      end
    end
  end
end
