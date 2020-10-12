module Webhooks
  class Log < ApplicationRecord
    belongs_to :webhook, foreign_key: :webhooks_webhook_id, class_name: '::Webhooks::Webhook', dependent: :destroy

    validates :url, presence: true
    validates :event_name, presence: true
    validates :response_code, presence: true

    serialize :response_headers, Hash
    serialize :request_headers, Hash

    validates :request_headers, presence: true
    validates :request_body, presence: true

    def self.newest(limit: 10)
      order(updated_at: :desc).limit(limit)
    end
  end
end
