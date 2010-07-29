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
          prefixed = "backlogs.#{attr}"
          v = self.pref[prefixed]
          v = nil if v == ''

          case attr
            when :task_color
              if !v && (!set_to || set_to == '')
                colors = UserPreference.find(:all).collect{|p| p[prefixed].to_s.upcase}.select{|p| p != ''}
                1.upto(50).each {|attempt|
                  set_to = "##{rand(0xFFFFFF).to_s(16).upcase}"
                  break unless colors.include?(set_to)
                }
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
