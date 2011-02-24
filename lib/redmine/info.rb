module Redmine
  module Info
    class << self
      def app_name; 'ChiliProject' end
      def url; 'https://www.chiliproject.org/' end
      def help_url
        "https://www.chiliproject.org/help/v#{Redmine::VERSION.to_semver}"
      end
      def versioned_name; "#{app_name} #{Redmine::VERSION}" end

      # Creates the url string to a specific Redmine issue
      def issue(issue_id)
        url + 'issues/' + issue_id.to_s
      end
    end
  end
end
