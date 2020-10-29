class CustomCoder
  def load(value)
    if value.nil?
      {}
    else
      YAML.load(value)
    end
  end

  def dump(value)
    YAML.dump(value)
  end
end

class Widget < ActiveRecord::Base
  self.primary_key = :w_id

  default_scope -> { where(active: true) }

  serialize :data, Hash
  serialize :json_data, JSON
  serialize :unspecified_data
  serialize :custom_data, CustomCoder.new
end
