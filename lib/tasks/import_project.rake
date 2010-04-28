desc 'Import project into Redmine'

require 'yaml' 

class Importer
    def initialize(project, config, commit)
        @yaml_project = project
        @config = config

        @commit = commit

        @project = Project.find_by_name(project['name'])
        raise "Project #{project['name']} does not exist" if @project.nil?

        @tracker = {}
        self.prime_trackers
        @default_tracker = nil

        @role = {}
        @rolemap = config['roles'] || {}
        @sprint = {}
        @priority = {}
        @time_entry_activity = config['activity'] || {}
        @users = {}
    end

    def prime_trackers
        @config['trackers'].each_pair {|name, data|
            self.prime_tracker(name, data['tracker'], data['states'])
            @default_tracker = name if data['default']
        }
    end

    def prime_tracker(issuetype, trackername, statusmap)
        return if @tracker.include? issuetype and @tracker.include? trackername

        if issuetype == '_task_':
            tracker = Tracker.find_by_id(Task.tracker)
            trackername = tracker.name
        else
            tracker = Tracker.find_by_name(trackername)
        end
        raise "Cannot find tracker #{issuetype}/#{trackername}, available trackers: #{@tracker.keys.join(', ')}" if tracker.nil?

        statusmap ||= {}

        foreign = {}
        redmine = {}
        tracker.workflows.each {|wf|
            statusmap.each_pair {|f, r|
                foreign[f] = wf.old_status if not foreign[f] and wf.old_status.name == r
                foreign[f] = wf.new_status if not foreign[f] and wf.new_status.name == r
            }
            redmine[wf.old_status.name] = wf.old_status
            redmine[wf.new_status.name] = wf.new_status
        }
        redmine.each_pair {|name, status|
            foreign[name] = status if foreign[name]
        }

        @tracker[issuetype] = {'tracker' => tracker, 'status' => foreign}
    end

    def tracker(name, status = nil)
        name = @default_tracker if not name
        self.prime_tracker(name, name, nil) if not @tracker.include? name

        t = @tracker[name]
        raise "Tracker #{name} not found, available trackers: #{@tracker.keys.join(', ')}" if t.nil?

        return t['tracker'] if status.nil?

        s = t['status'][status]
        raise "Status '#{status}' not found on tracker '#{name}', available: #{t['status'].keys.join(', ')}" if s.nil?

        return t['status'][status]
    end

    def role(name)
        role = @role[name] || Role.find_by_name(@rolemap[name]) || Role.find_by_name(name)
        raise "Role '#{name}'/'#{@rolemap[name]}' not found, available: #{Role.find(:all).collect{|r| r.name}.join(', ')}" if role.nil?

        @role[name] = role

        return role
    end

    def self.newpass
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        pass = ""
        1.upto(20) { |i| pass << chars[rand(chars.size-1)] }
        return pass
    end

    def user(username)
        u = @users[username] || User.find_by_login(username)
        raise "Cannot find user '#{username}'" if not u
        @users[username] = u
        return u
    end

    def add_members
        return if @yaml_project['members'].nil?

        @yaml_project['members'].each {|username, data|
            user = User.find_by_login(username)
            if user.nil?
                puts "New user #{username} (#{data['firstname']} #{data['lastname']}) will be created" if not @commit
                user = User.new
                user.login = username
                user.password = Importer.newpass
                user.firstname = data['firstname'].nil? ? username : data['firstname']
                user.lastname = data['lastname'].nil? ? username : data['lastname']
                user.mail = data['email'].nil? ? username + '@localhost.localdomain' : data['email']
                user.admin = data['admin'].nil? ? false : data['admin']
                user.status = data['active'] ? 1 : 3
                user.type = "User"
                user.save! if @commit
                @users[username] = user if not @commit
            end

            membership = Member.find(:first, :conditions=> { :user_id => user.id, :project_id => @project.id })
            if membership.nil?
                membership = Member.new
                membership.user = user
                membership.project = @project
                membership.roles << self.role(data['role'])
                membership.save! if @commit
            else
                membership.roles << self.role(data['role'])
                membership.save! if @commit
            end
        }
    end

    def priority(p)
        return IssuePriority.default if p.nil?

        return @priority[p] if not @priority[p].nil?

        prio = nil
        if not @config['priority'].nil?
            if not @config['priority'][p].nil?
                prio = IssuePriority.find_by_name(@config['priority'][p])
                @priority[p] = prio
                @priority[@config['priority'][p]] = prio
            end
        else
            prio = IssuePriority.find_by_name(p)
            @priority[p] = prio
        end

        raise "No priority '#{p}'" if prio.nil?
        return prio
    end

    def history(issue, j)
        journal = Journal.new(:journalized => issue, :user => self.user(j['username']), :created_on => j['timestamp'])

        activity = j['activity'] || {}

        activity.each_pair {|prop, changes|
            if prop == 'status'
                journal.details << JournalDetail.new(
                    :property => 'attr',
                    :prop_key => 'status',
                    :old_value => self.tracker(issue.tracker.name, changes['old']),
                    :value => self.tracker(issue.tracker.name, changes['new']))

            elsif prop == 'remaining_hours'
                journal.details << JournalDetail.new(
                    :property => 'attr',
                    :prop_key => 'remaining_hours',
                    :old_value => changes['old'],
                    :value => changes['new'])
            else
                raise "Unhandled history '#{prop}'"
            end
        }

        journal.save if @commit
    end

    def issues
        @issues = {}
        @yaml_project['issues'].each_pair {|id, i|
        
            issue = Issue.new

            i['history'].sort! {|a, b| a['timestamp'] <=> b['timestamp']} if i['history']

            issue.subject = i['name']
            issue.project = @project
            issue.tracker = self.tracker(i['type'])
            issue.status = self.tracker(i['type'], i['status'])
            issue.author = self.user(i['author'])
            issue.assigned_to = self.user(i['assigned_to']) if i['assigned_to']
            issue.description = i['description']
            issue.priority = self.priority(i['priority'])
            issue.fixed_version = @sprints[i['sprint']]
            issue.estimated_hours = i['estimated_hours']
            issue.remaining_hours = i['remaining_hours']

            issue.created_on = i['created']
            if i['history']
                issue.updated_on = i['history'][-1]['timestamp']
            else
                issue.updated_on = issue.created_on
            end

            issue.done_ratio = i['done'] || 0

            issue.position = i['position']
            issue.story_points = i['points']

            issue.save! if @commit
            @issues[id] = issue

            if i['history']
                i['history'].each{|j|
                    self.history(issue, j)
                }
            end
        }

        puts "Reparenting and blockers..."
        @yaml_project['issues'].each_pair {|id, i|
            if i['parent']
                @issues[id].parent_issue_id = @issues[i['parent']].id
                @issues[id].save! if @commit
            end

            if i['blocks']
                i['blocks'].each { |blocked|
                    relation = IssueRelation.new :relation_type => IssueRelation::TYPE_BLOCKS
                    relation.issue_from = @issues[id]
                    relation.issue_to =  @issues[blocked]
                    relation.save! if @commit
                }
            end
        }
        puts "Rebuilding issues tree..."
        Issue.rebuild! if @commit
    end

    def sprints
        return if @yaml_project['sprints'].nil?

        @sprints = {}
        @yaml_project['sprints'].each_pair {|id, s|
            sprint = Version.new
            sprint.project = @project
            sprint.name = s['name']
            sprint.description = s['description']
            sprint.sprint_start_date = s['start']
            sprint.effective_date = s['end']

            # can't assign stories to closed sprint
            sprint.status = 'open'
            sprint.save! if @commit
            @sprints[id] = sprint

            if s['wiki'] and @commit
                sprint_wiki = Sprint.find_by_id(sprint.id)
                page_tag = sprint_wiki.wiki_page
                if page_tag
                    wiki = @project.wiki
                    page = wiki.find_or_new_page(page_tag)
                    page.content = WikiContent.new
                    page.content.text = s['wiki']
                    page.save!
                end
            end

            if s['burndown']
                s['burndown'].each {|bd|
                    bdd = BurndownDay.new
                    bdd.created_at = bd['date']
                    bdd.updated_at = bd['date']
                    bdd.points_committed = bd['points_committed'] || 0
                    bdd.points_accepted = bd['points_accepted'] || 0
                    bdd.points_resolved = bd['points_resolved'] || 0
                    bdd.remaining_hours = bd['remaining_hours'] || 0
                    bdd.version_id = sprint.id
                    bdd.save! if @commit
                }
            end

            if s['stories']
                s['stories'].each {|story|
                    self.story(story, sprint)
                }
            end
        }
    end

    def close_sprints
        return if @yaml_project['sprints'].nil?

        @yaml_project['sprints'].each_pair {|id, s|
            @sprints[id].update_attribute(:status, 'closed') if not s['open'] and @commit
        }
    end

    def time_entry_activity(activity)
        act = TimeEntryActivity.find_by_name(@time_entry_activity[activity] || activity || @time_entry_activity['default'])
        raise "Unknown activity #{activity}, available: #{TimeEntryActivity.find(:all).collect{|a| a.name}.join(', ')}" if not act
        return act
    end

    def time_entries
        return if @yaml_project['time_entries'].nil?

        @yaml_project['time_entries'].each {|te|
            tl = TimeEntry.new(
                :project => @project,
                :issue => @issues[te['issue']],
                :user => self.user(te['username']),
                :spent_on => te['timestamp'],
                :hours => te['hours'],
                :comments => te['comments'],
                :activity => self.time_entry_activity(te['activity']))
            tl.save if @commit
        }
    end

    def import!
        puts "Importing '#{@project.name}'..."
        if @config['clear'] and @commit
            puts "Clearing time entries..."
            TimeEntry.destroy_all({ :project_id => @project })

            puts "Clearing issues..."
            Issue.destroy_all({ :project_id => @project })

            puts "Clearing burndown..."
            Version.find(:all, :conditions => { :project_id => @project }).each {|sprint|
                BurndownDay.destroy_all({ :version_id => sprint.id })
            }

            puts "Clearing sprints..."
            Version.destroy_all({ :project_id => @project })
        end

        puts "Adding new users..."
        self.add_members

        puts "Adding sprints..."
        self.sprints

        puts "Adding issues..."
        self.issues

        puts "Closing sprints..."
        self.close_sprints

        puts "Time registration..."
        self.time_entries

        puts "Done!"
    end
end

namespace :redmine do
    namespace :backlogs_plugin do
        task :import_project => :environment do
            raise "usage: rake redmine:backlogs_plugin:import_project project=<...> config=<...> mode=[commit|verify]" unless ENV['project'] and ENV['config']
            importer = Importer.new(YAML::load_file(ENV['project']), YAML::load_file(ENV['config']), ENV['mode'] == 'commit')
            importer.import!
        end
    end
end
