class License < ActiveRecord::Base
  def self.current
    License.order('created_at DESC').first
  end
end
