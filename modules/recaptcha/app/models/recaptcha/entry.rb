module Recaptcha
  class Entry < ::ApplicationRecord
    self.table_name_prefix = 'recaptcha_'
    belongs_to :user
  end
end
