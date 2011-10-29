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
  # An extension module for the +has_many+ association with journals.
  module Versions
    # Returns all journals between (and including) the two given arguments. See documentation for
    # the +at+ extension method for what arguments are valid. If either of the given arguments is
    # invalid, an empty array is returned.
    #
    # The +between+ method preserves returns an array of journal records, preserving the order
    # given by the arguments. If the +from+ value represents a journal before that of the +to+
    # value, the array will be ordered from earliest to latest. The reverse is also true.
    def between(from, to)
      from_number, to_number = journal_at(from), journal_at(to)
      return [] if from_number.nil? || to_number.nil?

      condition = (from_number == to_number) ? to_number : Range.new(*[from_number, to_number].sort)
      all(
        :conditions => {:version => condition},
        :order => "#{aliased_table_name}.version #{(from_number > to_number) ? 'DESC' : 'ASC'}"
      )
    end

    # Returns all journal records created before the journal associated with the given value.
    def before(value)
      return [] if (version = journal_at(value)).nil?
      all(:conditions => "#{aliased_table_name}.version < #{version}")
    end

    # Returns all journal records created after the journal associated with the given value.
    #
    # This is useful for dissociating records during use of the +reset_to!+ method.
    def after(value)
      return [] if (version = journal_at(value)).nil?
      all(:conditions => "#{aliased_table_name}.version > #{version}")
    end

    # Returns a single journal associated with the given value. The following formats are valid:
    # * A Date or Time object: When given, +to_time+ is called on the value and the last journal
    #   record in the history created before (or at) that time is returned.
    # * A Numeric object: Typically a positive integer, these values correspond to journal numbers
    #   and the associated journal record is found by a journal number equal to the given value
    #   rounded down to the nearest integer.
    # * A String: A string value represents a journal tag and the associated journal is searched
    #   for by a matching tag value. *Note:* Be careful with string representations of numbers.
    # * A Symbol: Symbols represent association class methods on the +has_many+ journals
    #   association. While all of the built-in association methods require arguments, additional
    #   extension modules can be defined using the <tt>:extend</tt> option on the +journaled+
    #   method. See the +journaled+ documentation for more information.
    # * A Version object: If a journal object is passed to the +at+ method, it is simply returned
    #   untouched.
    def at(value)
      case value
        when Date, Time then last(:conditions => ["#{aliased_table_name}.created_at <= ?", value.to_time])
        when Numeric then find_by_version(value.floor)
        when Symbol then respond_to?(value) ? send(value) : nil
        when Journal then value
      end
    end

    # Returns the journal number associated with the given value. In many cases, this involves
    # simply passing the value to the +at+ method and then returning the subsequent journal number.
    # Hoever, for Numeric values, the journal number can be returned directly and for Date/Time
    # values, a default value of 1 is given to ensure that times prior to the first journal
    # still return a valid journal number (useful for rejournal).
    def journal_at(value)
      case value
        when Date, Time then (v = at(value)) ? v.version : 1
        when Numeric then value.floor
        when Symbol then (v = at(value)) ? v.version : nil
        when String then nil
        when Journal then value.version
      end
    end
  end
end