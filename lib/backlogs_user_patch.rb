require_dependency 'user'

module Backlogs
  module UserPatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
    end
  
    module ClassMethods
    end
  
    module InstanceMethods
  
        def backlogs_preference(attr, set_to = nil)
          prefixed = "backlogs_#{attr}".intern
          v = self.pref[prefixed]
          v = nil if v == ''

          case attr
            when :task_color
              if !v && (!set_to || set_to == '')
                colors = UserPreference.find(:all).collect{|p| p[prefixed].to_s.upcase}.select{|p| p != ''}
                50.times do
                  min = 0x999999
                  set_to = "##{(min + rand(0xFFFFFF-min)).to_s(16).upcase}"
                  break unless colors.include?(set_to)
                end
              end

            else
              raise "Unsupported attribute '#{attr}'"
          end

          if set_to
            v = set_to
            self.pref[prefixed] = v
            self.pref.save!
          end

          return v
        end

    end
  end
end

User.send(:include, Backlogs::UserPatch) unless User.included_modules.include? Backlogs::UserPatch
