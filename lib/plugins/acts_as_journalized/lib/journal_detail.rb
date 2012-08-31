#-- encoding: UTF-8
class JournalDetail
  attr_reader :prop_key, :value, :old_value

  def initialize(prop_key, old_value, value)
    @prop_key = prop_key
    @old_value = old_value
    @value = value
  end
end
