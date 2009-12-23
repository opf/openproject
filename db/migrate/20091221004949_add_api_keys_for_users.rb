class AddApiKeysForUsers < ActiveRecord::Migration
  def self.up
    say_with_time("Generating API keys for active users") do
      User.active.all(:include => :api_token).each do |user|
        user.api_key
      end
    end
  end

  def self.down
    # No-op
  end
end
