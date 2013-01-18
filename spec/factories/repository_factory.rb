FactoryGirl.define do
  factory :repository, :class => Repository::Filesystem do
    # Setting.enabled_scm should include "Filesystem" to successfully save the created repository
    url 'file:///tmp/test_repo'
    project
  end
end
