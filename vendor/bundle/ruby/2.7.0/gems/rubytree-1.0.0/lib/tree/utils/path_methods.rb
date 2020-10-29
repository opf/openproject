# path_methods.rb - This file is part of the RubyTree package.
#
# = path_methods.rb - Provides methods for extracting the node path.
#
# Author::  Marco Ziccardi and Anupam Sengupta (anupamsg@gmail.com)
#
# Time-stamp: <2015-05-30 16:04:00 anupam>
#
# Copyright (C) 2015 Anupam Sengupta <anupamsg@gmail.com>
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

module Tree::Utils
  # Provides utility methods for path extraction
  module TreePathHandler
    # noinspection RubyUnusedLocalVariable
    def self.included(base)

      # @!group Node Path

      # Returns the path of this node from the root as a string, with the node
      # names separated using the specified separator. The path is listed left
      # to right from the root node.
      #
      # @param separator The optional separator to use. The default separator is
      #                  '+=>+'.
      #
      # @return [String] The node path with names separated using the specified
      #                  separator.
      def path_as_string(separator = '=>')
        path_as_array.join(separator)
      end

      # Returns the node-names from this node to the root as an array. The first
      # element is the root node name, and the last element is this node's name.
      #
      # @return [Array] The array containing the node names for the path to this
      # node
      def path_as_array
        get_path_name_array.reverse
      end

      # @!visibility private
      #
      # Returns the path names in an array. The first element is the name of
      # this node, and the last element is the root node name.
      #
      # @return [Array] An array of the node names for the path from this node
      #                 to its root.
      def get_path_name_array(current_array_path = [])
        path_array = current_array_path + [name]

        if !parent              # If detached node or root node.
          path_array
        else                    # Else recurse to parent node.
          path_array = parent.get_path_name_array(path_array)
        end
      end

      protected :get_path_name_array

      # @!endgroup
    end # self.included
  end

end
