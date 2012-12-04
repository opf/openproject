FactoryGirl.define do
  factory :repository, :class => Repository::Filesystem do
    url  'file:///tmp/test_repo'
    project
  end
end

