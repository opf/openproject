module Activities
  Event = Struct.new(:provider,
                     :event_id,
                     :event_name,
                     :event_title,
                     :event_description,
                     :author_id,
                     :event_datetime,
                     :journable_id,
                     :project_id,
                     :event_type,
                     :event_path,
                     :event_url,
                     # attributes below are eager loaded by Activities::Fetcher
                     :event_author,
                     :journal,
                     :project)
end
