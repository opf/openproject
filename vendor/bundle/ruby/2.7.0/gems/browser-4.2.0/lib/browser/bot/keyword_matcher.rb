# frozen_string_literal: true

module Browser
  class Bot
    class KeywordMatcher
      def self.call(ua, _browser)
        ua =~ /crawl|fetch|search|monitoring|spider|bot/
      end
    end
  end
end
