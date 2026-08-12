# frozen_string_literal: true

class AddMemberLookupAttributeToSynchronizedFilters < ActiveRecord::Migration[7.1]
  def change
    add_column :ldap_groups_synchronized_filters, :member_lookup_attribute, :string
  end
end
