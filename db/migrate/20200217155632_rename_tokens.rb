class RenameTokens < ActiveRecord::Migration[6.0]
  class Token < ActiveRecord::Base
  end

  def up
    Token.where(type: 'Token::Rss').update_all(type: 'Token::RSS')
    Token.where(type: 'Token::Api').update_all(type: 'Token::API')
  end

  def down
    Token.where(type: 'Token::RSS').update_all(type: 'Token::Rss')
    Token.where(type: 'Token::API').update_all(type: 'Token::Api')
  end
end
