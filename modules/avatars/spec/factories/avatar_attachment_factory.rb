FactoryBot.define do
  factory :avatar_attachment, class: Attachment do
    author       factory: :user
    container    factory: :work_package
    description  { "avatar" }
    filename     { "avatar.jpg" }
    content_type { "image/jpeg" }
    file do
      File.open(File.expand_path('../../fixtures/valid.jpg', __FILE__))
    end
  end
end
