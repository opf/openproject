module Redmine
  module Info
    class << self
      def app_name; 'Redmine' end
      def url; 'http://www.redmine.org/' end
      def help_url; 'http://www.redmine.org/guide' end
      def versioned_name; "#{app_name} #{Redmine::VERSION}" end

      # Creates the url string to a specific Redmine issue
      def issue(issue_id)
        url + 'issues/' + issue_id.to_s
      end
    end
  end
end
