Factory.define :meeting do |m|
  m.sequence(:title) { |n| "Meeting #{n}" }
end
