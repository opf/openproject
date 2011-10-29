#-- encoding: UTF-8
# This file included as part of the acts_as_journalized plugin for
# the redMine project management software; You can redistribute it
# and/or modify it under the terms of the GNU General Public License
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
# The original copyright and license conditions are:
# Copyright (c) 2009 Steve Richert
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Redmine::Acts::Journalized
  # Allows for easy application-wide configuration of options passed into the +journaled+ method.
  module Configuration
    # The VestalVersions module is extended by VestalVersions::Configuration, allowing the
    # +configure method+ to be used as follows in a Rails initializer:
    #
    #   VestalVersions.configure do |config|
    #     config.class_name = "MyCustomVersion"
    #     config.dependent = :destroy
    #   end
    #
    # Each variable assignment in the +configure+ block corresponds directly with the options
    # available to the +journaled+ method. Assigning common options in an initializer can keep your
    # models tidy.
    #
    # If an option is given in both an initializer and in the options passed to +journaled+, the
    # value given in the model itself will take precedence.
    def configure
      yield Configuration
    end

    class << self
      # Simply stores a hash of options given to the +configure+ block.
      def options
        @options ||= {}
      end

      # If given a setter method name, will assign the first argument to the +options+ hash with
      # the method name (sans "=") as the key. If given a getter method name, will attempt to
      # a value from the +options+ hash for that key. If the key doesn't exist, defers to +super+.
      def method_missing(symbol, *args)
        if (method = symbol.to_s).sub!(/\=$/, '')
          options[method.to_sym] = args.first
        else
          options.fetch(method.to_sym, super)
        end
      end
    end
  end
end
