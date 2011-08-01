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
  # Provides a way for information to be associated with specific journals as to who was
  # responsible for the associated update to the parent.
  module Users
    def self.included(base) # :nodoc:
      Journal.send(:include, JournalMethods)

      base.class_eval do
        include InstanceMethods

        attr_accessor :updated_by
        alias_method_chain :journal_attributes, :user
      end
    end

    # Methods added to journaled ActiveRecord::Base instances to enable journaling with additional
    # user information.
    module InstanceMethods
      private
        # Overrides the +journal_attributes+ method to include user information passed into the
        # parent object, by way of a +updated_by+ attr_accessor.
        def journal_attributes_with_user
          journal_attributes_without_user.merge(:user_id => journal_user.try(:id) || updated_by.try(:id) || User.current.try(:id))
        end
    end

    # Instance methods added to Redmine::Acts::Journalized::Journal to accomodate incoming
    # user information.
    module JournalMethods
      def self.included(base) # :nodoc:
        base.class_eval do
          belongs_to :user

          alias_method_chain :user=, :name
        end
      end

      # Overrides the +user=+ method created by the polymorphic +belongs_to+ user association.
      # Based on the class of the object given, either the +user+ association columns or the
      # +user_name+ string column is populated.
      def user_with_name=(value)
        case value
          when ActiveRecord::Base then self.user_without_name = value
          else self.user = User.find_by_login(value)
        end
      end
    end
  end
end
