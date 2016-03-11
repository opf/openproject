#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject::Costs::Patches::ApplicationHelperPatch
  def self.included(base) # :nodoc:
    # Same as typing in the class
    base.class_eval do
      def link_to_cost_object(cost_object, options = {})
        title = nil
        subject = nil
        if options[:subject] == false
          subject = "#{t(:label_cost_object)} ##{cost_object.id}"
          title = truncate(cost_object.subject, length: 60)
        else
          subject = cost_object.subject
          if options[:truncate]
            subject = truncate(subject, length: options[:truncate])
          end
        end
        s = link_to subject, cost_object_path(cost_object), class: cost_object.css_classes, title: title
        s = "#{h cost_object.project} - " + s if options[:project]
        s
      end
    end
  end
end
