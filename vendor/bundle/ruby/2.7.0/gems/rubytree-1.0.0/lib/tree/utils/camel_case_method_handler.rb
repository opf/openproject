# camel_case_methods.rb - This file is part of the RubyTree package.
#
# = camel_case_methods.rb - Provides conversion from CamelCase to snake_case.
#
# Author::  Anupam Sengupta (anupamsg@gmail.com)
#
# Time-stamp: <2017-12-21 13:42:15 anupam>
#
# Copyright (C) 2012, 2013, 2015, 2017 Anupam Sengupta <anupamsg@gmail.com>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# - Neither the name of the organization nor the names of its contributors may
#   be used to endorse or promote products derived from this software without
#   specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require_relative '../../../lib/tree'
require 'structured_warnings'

module Tree::Utils
  # Provides utility functions to handle CamelCase methods, and redirect
  # invocation of such methods to the snake_case equivalents.
  module CamelCaseMethodHandler
    def self.included(base)
      # @!visibility private
      # Allow the deprecated CamelCase method names.  Display a warning.
      # :nodoc:
      def method_missing(meth, *args, &blk)
        if self.respond_to?((new_method_name = to_snake_case(meth)))
          warn StructuredWarnings::DeprecatedMethodWarning,
               'The camelCased methods are deprecated. ' +
               "Please use #{new_method_name} instead of #{meth}"
          send(new_method_name, *args, &blk)
        else
          super
        end
      end

      protected

      # @!visibility private
      # Convert a CamelCasedWord to a underscore separated camel_cased_word.
      #
      # @param [String] camel_cased_word The word to be converted to snake_case.
      # @return [String] the snake_cased_word.
      def to_snake_case(camel_cased_word)
        word = camel_cased_word.to_s
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!('-', '_')
        word.downcase!
        word
      end

    end # self.included
  end
end
