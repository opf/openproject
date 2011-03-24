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
        def content_for_review(content, content_type)
          meeting = content.meeting
          c_type = content_type.gsub(/^meeting_/, '')
          redmine_headers 'Project' => meeting.project.identifier,
                          'Meeting-Id' => meeting.id
          message_id content
          cc meeting.watcher_recipients # works only in production environment
          subject "[#{meeting.project.name}] #{l(:"label_#{content_type}")}: #{meeting.title}"
          body :content => content,
               :content_url => url_for(:controller => 'meetings', :action => 'show', :id => meeting, :tab => c_type),
               :c_type => c_type,
               :meeting => meeting,
               :meeting_url => url_for(:controller => 'meetings', :action => 'show', :id => meeting)
          render_multipart('send_content', body)
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