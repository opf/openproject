collection @objects => 'objects'
attributes :id
node(:time_ago) { |_| distance_of_time_in_words(20000) }
