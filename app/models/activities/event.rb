module Activities
  Event = Struct.new(:provider,
                     :event_name,
                     :event_title,
                     :event_description,
                     :author_id,
                     :event_author,
                     :event_datetime,
                     :journable_id,
                     :project_id,
                     :project,
                     :event_type,
                     :event_path,
                     :event_url,
                     keyword_init: true)
end
