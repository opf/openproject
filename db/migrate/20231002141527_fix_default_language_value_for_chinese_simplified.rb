class FixDefaultLanguageValueForChineseSimplified < ActiveRecord::Migration[7.0]
  def up
    Setting.where(name: "default_language", value: "zh").update_all(value: "zh-CN")
  end
end
