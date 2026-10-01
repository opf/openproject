# frozen_string_literal: true

class SuffixOrPrefixCurrencyFormat < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE settings
      SET value = '%n %u'
      WHERE name = 'costs_currency_format'
      AND value NOT IN ('%u %n', '%n %u');
    SQL
  end
end
