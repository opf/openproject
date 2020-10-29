# json_converter.rb - This file is part of the RubyTree package.
#
# = json_converter.rb - Provides conversion to and from JSON.
#
# Author::  Anupam Sengupta (anupamsg@gmail.com)
#
# Time-stamp: <2015-05-30 14:20:20 anupam>
#
# Copyright (C) 2012, 2013, 2014, 2015 Anupam Sengupta <anupamsg@gmail.com>
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

require_relative '../utils/utils'
require 'json'

# Provides utility methods to convert a {Tree::TreeNode} to and from
# JSON[http://flori.github.com/json/].
module Tree::Utils::JSONConverter

  def self.included(base)
    base.extend(ClassMethods)
  end

  # @!group Converting to/from JSON

  # Creates a JSON ready Hash for the #to_json method.
  #
  # @author Eric Cline (https://github.com/escline)
  # @since 0.8.3
  #
  # @return A hash based representation of the JSON
  #
  # Rails uses JSON in ActiveSupport, and all Rails JSON encoding goes through
  # +as_json+.
  #
  # @param [Object] options
  #
  # @see #to_json
  # @see http://stackoverflow.com/a/6880638/273808
  # noinspection RubyUnusedLocalVariable
  def as_json(options = {})

    json_hash = {
        name: name,
        content: content,
        JSON.create_id => self.class.name
    }

    if has_children?
      json_hash['children'] = children
    end

    json_hash

  end

  # Creates a JSON representation of this node including all it's children.
  # This requires the JSON gem to be available, or else the operation fails with
  # a warning message.  Uses the Hash output of #as_json method.
  #
  # @author Dirk Breuer (http://github.com/railsbros-dirk)
  # @since 0.7.0
  #
  # @return The JSON representation of this subtree.
  #
  # @see ClassMethods#json_create
  # @see #as_json
  # @see http://flori.github.com/json
  def to_json(*a)
    as_json.to_json(*a)
  end

  # ClassMethods for the {JSONConverter} module. Will become class methods in
  # the +include+ target.
  module ClassMethods
    # Helper method to create a Tree::TreeNode instance from the JSON hash
    # representation.  Note that this method should *NOT* be called directly.
    # Instead, to convert the JSON hash back to a tree, do:
    #
    #   tree = JSON.parse(the_json_hash)
    #
    # This operation requires the {JSON gem}[http://flori.github.com/json/] to
    # be available, or else the operation fails with a warning message.
    #
    # @author Dirk Breuer (http://github.com/railsbros-dirk)
    # @since 0.7.0
    #
    # @param [Hash] json_hash The JSON hash to convert from.
    #
    # @return [Tree::TreeNode] The created tree.
    #
    # @see #to_json
    # @see http://flori.github.com/json
    def json_create(json_hash)

      node = new(json_hash['name'], json_hash['content'])

      json_hash['children'].each do |child|
        node << child
      end if json_hash['children']

      node

    end
  end
end
