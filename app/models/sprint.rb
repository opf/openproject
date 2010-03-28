class Sprint < Version
    unloadable

    named_scope :open_sprints, lambda { |project|
        {
            :order => 'start_date ASC, effective_date ASC',
            :conditions => [ "status = 'open' and project_id = ?", project.id ]
        }
    }

    def stories
        return Story.sprint_backlog(self)
    end

    def points
        return stories.sum('story_points')
    end
   
    def wiki_page
        if ! project.wiki
            return ''
        end

        if wiki_page_title.nil? || wiki_page_title.blank?
            self.update_attribute(:wiki_page_title, name.gsub(/\s+/, '_').gsub(/[^_a-zA-Z0-9]/, ''))
        end

        return wiki_page_title
    end

end
