FactoryBot.define do
  factory :avatar_attachment, class: Attachment do
    author       factory: :user
    container    factory: :work_package
    description  { "avatar" }
    filename     { "avatar.jpg" }
    content_type { "image/jpeg" }
    file do
      OpenProject::Files.create_uploaded_file name: filename,
                                              content_type: content_type,
                                              binary: true
    end
  end
end
