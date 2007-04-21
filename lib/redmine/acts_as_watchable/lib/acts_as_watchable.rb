# ActsAsWatchable
module Redmine
  module Acts
    module Watchable
      def self.included(base) 
        base.extend ClassMethods
      end 

      module ClassMethods
        def acts_as_watchable(options = {})
          return if self.included_modules.include?(Redmine::Acts::Watchable::InstanceMethods)          
          send :include, Redmine::Acts::Watchable::InstanceMethods
          
          class_eval do
            has_many :watchers, :as => :watchable, :dependent => :delete_all
          end
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        def add_watcher(user)
          self.watchers << Watcher.new(:user => user)
        end
        
        def remove_watcher(user)
          return nil unless user && user.is_a?(User)
          Watcher.delete_all "watchable_type = '#{self.class}' AND watchable_id = #{self.id} AND user_id = #{user.id}"
        end
        
        def watched_by?(user)
          !self.watchers.find(:first,
                              :conditions => ["#{Watcher.table_name}.user_id = ?", user.id]).nil?
        end
        
        def watcher_recipients
          self.watchers.collect { |w| w.user.mail if w.user.mail_notification }.compact
        end

        module ClassMethods
          def watched_by(user)
            find(:all, 
                 :include => :watchers,
                 :conditions => ["#{Watcher.table_name}.user_id = ?", user.id])
          end
        end
      end
    end
  end
end 