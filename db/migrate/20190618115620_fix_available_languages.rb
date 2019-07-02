class FixAvailableLanguages < ActiveRecord::Migration[5.2]
  def up
    Setting.available_languages = Setting.available_languages.map do |lang|
      if lang == 'zh'
        'zh-CN'
      else
        lang
      end
    end

    User.where(language: 'zh').update_all(language: 'zh-CN')
  end

  def down
    Setting.available_languages = Setting.available_languages.map do |lang|
      if lang == 'zh-CN'
        'zh'
      else
        lang
      end
    end

    User.where(language: 'zh-CN').update_all(language: 'zh')
  end

  private
end
