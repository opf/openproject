module Plugin
  module Meeting
    module Project
      module ClassMethods
      end
      
      module InstanceMethods
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          #unloadable
          has_many :meetings, :include => [:author]
        end
      end
    end
    
    module Mailer
      module ClassMethods
      end
      
      module InstanceMethods
        def minutes_for_review(minutes)
          meeting = minutes.meeting
          redmine_headers 'Project' => meeting.project.identifier,
                          'Meeting-Id' => meeting.id
          message_id minutes
          cc meeting.watcher_recipients # works only in production environment
          subject "[#{meeting.project.name}] #{l(:label_meeting_minutes)}: #{meeting.title}"
          body :minutes => minutes,
               :minutes_url => url_for(:controller => 'meetings', :action => 'show', :id => meeting, :tab => 'minutes'),
               :meeting => meeting,
               :meeting_url => url_for(:controller => 'meetings', :action => 'show', :id => meeting)
          render_multipart('send_minutes', body)
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          helper :meetings
        end
      end
    end
  end
end