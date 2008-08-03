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
            has_many :watcher_users, :through => :watchers, :source => :user
          end
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        # Returns an array of users that are proposed as watchers
        def addable_watcher_users
          self.project.users.sort - self.watcher_users
        end
        
        # Adds user as a watcher
        def add_watcher(user)
          self.watchers << Watcher.new(:user => user)
        end
        
        # Removes user from the watchers list
        def remove_watcher(user)
          return nil unless user && user.is_a?(User)
          Watcher.delete_all "watchable_type = '#{self.class}' AND watchable_id = #{self.id} AND user_id = #{user.id}"
        end
        
        # Adds/removes watcher
        def set_watcher(user, watching=true)
          watching ? add_watcher(user) : remove_watcher(user)
        end
        
        # Returns if object is watched by user
        def watched_by?(user)
          !self.watchers.find(:first,
                              :conditions => ["#{Watcher.table_name}.user_id = ?", user.id]).nil?
        end
        
        # Returns an array of watchers' email addresses
        def watcher_recipients
          self.watchers.collect { |w| w.user.mail if w.user.active? }.compact
        end

        module ClassMethods
          # Returns the objects that are watched by user
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
