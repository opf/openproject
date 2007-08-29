module Redmine
  module Info
    class << self
      def app_name; 'Redmine' end
      def url; 'http://www.redmine.org/' end
      def versioned_name; "#{app_name} #{Redmine::VERSION}" end
    end
  end
end
