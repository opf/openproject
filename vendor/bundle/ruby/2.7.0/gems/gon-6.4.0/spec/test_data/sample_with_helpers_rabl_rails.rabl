collection :@objects => 'objects'
attributes :inspect
node(:time_ago) { distance_of_time_in_words(20000) }
