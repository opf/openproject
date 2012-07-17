Factory.define :group_user do |gu|
  gu.association :group, :factory => :group
  gu.association :user, :factory => :user
end
