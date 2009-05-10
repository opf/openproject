class PopulateMemberRoles < ActiveRecord::Migration
  def self.up
    MemberRole.delete_all
    Member.find(:all).each do |member|
      MemberRole.create!(:member_id => member.id, :role_id => member.role_id)
    end
  end

  def self.down
    MemberRole.delete_all
  end
end
