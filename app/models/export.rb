class Export < ApplicationRecord
  has_one(
    :job_status,
    -> { where(reference_type: "Export") },
    class_name: "JobStatus::Status",
    foreign_key: :reference_id
  )

  def ready?
    raise "subclass responsibility"
  end
end
