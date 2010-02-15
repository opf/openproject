require_dependency 'application_helper'

module CostsApplicationHelperPatch
  def self.included(base) # :nodoc:
    # Same as typing in the class 
    base.class_eval do
      def link_to_cost_object(cost_object, options={})
        title = nil
        subject = nil
        if options[:subject] == false
          subject = "#{l(:label_cost_object)} ##{cost_object.id}"
          title = truncate(cost_object.subject, :length => 60)
        else
          subject = cost_object.subject
          if options[:truncate]
            subject = truncate(subject, :length => options[:truncate])
          end
        end
        s = link_to subject, {:controller => "cost_objects", :action => "show", :id => cost_object}, 
                                                     :class => cost_object.css_classes,
                                                     :title => title
        s = "#{h cost_object.project} - " + s if options[:project]
        s
      end
    end
  end
end

ApplicationHelper.send(:include, CostsApplicationHelperPatch)