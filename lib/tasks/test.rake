desc 'Fix trackers after migration 011'

def assert
  raise "Assertion failed !" unless yield if $DEBUG
end

def test_order(stories, msg)
  return if (stories[0].position + 1 == stories[1].position) && (stories[1].position + 1 == stories[2].position)
  stories = stories.collect{|s| [s.id, s.position]}
  raise "#{msg} #{stories.inspect}"
end

namespace :redmine do
  namespace :backlogs_plugin do
    task :test => :environment do

      project = Project.find(:first)
      user = User.find(:first)
      prefix = 'BACKLOGS TEST STORY '

      Issue.find(:all, :conditions => ["subject LIKE ?", "#{prefix}%"]).each {|i| i.destroy }

      stories = []
      3.times do |id|
        story = Story.new
        story.project = project
        story.subject = "#{prefix}#{id}"
        story.author = user
        story.tracker_id = Story.trackers[0]
        story.save!
        stories << story
      end

      puts stories.collect{|s| [s.id, s.position]}.inspect

      test_order(stories, 'init')

      # move story down
      stories[0].move_after stories[1].id
      stories[0], stories[1] = stories[1], stories[0]
      test_order(stories, '0 after 1')

      # move story up
      stories[2].move_after stories[0].id
      stories[2], stories[1] = stories[1], stories[2]
      test_order(stories, 'up')

      # move story to top
      stories[1].move_after nil
      stories[0], stories[1] = stories[1], stories[0]
      test_order(stories, 'top')

    end
  end
end
