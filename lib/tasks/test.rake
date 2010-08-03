desc 'Fix trackers after migration 011'

def prios(stories)
  p = []

  stories.each { |id|
    story = Story.find(id)
    p << [id, story.position]
  }

  return p
end

$MSG = nil
def report(stories, msg)
  $MSG = msg
  puts "#{msg} #{prios(stories).inspect}"
end

def verify(stories)
  p = prios(stories)
  (1..p.size - 1).each { |i|
    raise "Failed #{$MSG}: #{p.inspect}" if p[i][1] <= p[i-1][1]
  }
  puts "success: #{p.inspect}"
end

def move(msg, stories, src, after)
  report(stories, msg)

  Story.find(stories[src]).move_after(after ? stories[after] : nil)

  v = stories[src]
  if after.nil?
    stories.delete_at(src)
    stories.insert(0, v)
  else
    o = stories[after]
    stories.delete_at(src)
    stories.insert(stories.index(o) + 1, v)
  end

  verify(stories)

  return stories
end

namespace :redmine do
  namespace :backlogs_plugin do
    task :test => :environment do

      project = Project.find(:first)
      user = User.find(:first)
      prefix = 'BACKLOGS TEST STORY '

      Issue.find(:all, :conditions => ["subject LIKE ?", "#{prefix}%"]).each {|i| i.destroy }

      stories = []
      4.times do |id|
        story = Story.new
        story.project = project
        story.subject = "#{prefix}#{id}"
        story.author = user
        story.tracker_id = Story.trackers[0]
        story.save!
        stories << story.id
      end

      Story.find(stories[-1]).fixed_version = Version.find(:first)

      report(stories, 'init')

      # move story down
      stories = move('0 after 1', stories, 0, 1)

      # move story up
      stories = move('up', stories, 2, 0)

      # move story to top
      stories = move('top', stories, 2, nil)

      # move into backlog
      stories = move('last to 2nd', stories, -1, 0)

    end
  end
end
