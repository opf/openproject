class RenamePortugueseLocale < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE users SET language = 'pt-BR' WHERE language = 'pt'"
    execute "UPDATE settings SET value = 'pt-BR' WHERE name = 'default_language' AND value = 'pt'"
    modify_available_languages!("pt", "pt-BR")
  end

  def down
    execute "UPDATE users SET language = 'pt' WHERE language = 'pt-BR'"
    execute "UPDATE settings SET value = 'pt' WHERE name = 'default_language' AND value = 'pt-BR'"
    modify_available_languages!("pt-BR", "pt")
  end

  private

  def modify_available_languages!(from, to)
    languages = Setting.available_languages
    if languages.include?(from)
      languages << to
      languages.delete(from)
      Setting.available_languages = languages
    end
  end
end
