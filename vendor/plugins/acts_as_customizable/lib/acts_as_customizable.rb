# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

module Redmine
  module Acts
    module Customizable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_customizable(options = {})
          return if self.included_modules.include?(Redmine::Acts::Customizable::InstanceMethods)
          cattr_accessor :customizable_options
          self.customizable_options = options
          has_many :custom_values, :dependent => :delete_all, :as => :customized
          before_validation_on_create { |customized| customized.custom_field_values }
          # Trigger validation only if custom values were changed
          validates_associated :custom_values, :on => :update, :if => Proc.new { |customized| customized.custom_field_values_changed? }
          send :include, Redmine::Acts::Customizable::InstanceMethods
          # Save custom values when saving the customized object
          after_save :save_custom_field_values
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        def available_custom_fields
          CustomField.find(:all, :conditions => "type = '#{self.class.name}CustomField'",
                                 :order => 'position')
        end
        
        def custom_field_values=(values)
          @custom_field_values_changed = true
          values = values.stringify_keys
          custom_field_values.each do |custom_value|
            custom_value.value = values[custom_value.custom_field_id.to_s] if values.has_key?(custom_value.custom_field_id.to_s)
          end if values.is_a?(Hash)
        end
        
        def custom_field_values
          @custom_field_values ||= available_custom_fields.collect { |x| custom_values.detect { |v| v.custom_field == x } || custom_values.build(:custom_field => x, :value => nil) }
        end
        
        def custom_field_values_changed?
          @custom_field_values_changed == true
        end
        
        def custom_value_for(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          custom_values.detect {|v| v.custom_field_id == field_id }
        end
        
        def save_custom_field_values
          custom_field_values.each(&:save)
          @custom_field_values_changed = false
          @custom_field_values = nil
        end
        
        module ClassMethods
        end
      end
    end
  end
end
