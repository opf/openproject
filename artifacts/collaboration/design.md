# Slice 7: Collaboration Enhancement - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 7
**Dependencies:**
- Slice 2 (3D Viewer) - requires annotation tools
- Slice 3 (Linking) - for element-aware comments

---

## Current State Analysis

### Existing Capabilities (Community Edition)
✅ **BCF Comments**: Linked to journals
✅ **BCF Viewpoints**: Save/restore camera positions
✅ **Revit Integration**: BCF API support

### Limitations
- Comments update via page refresh (no real-time)
- No presence indicators (who's viewing)
- No @mentions or notifications
- Limited markup tools

---

## Enterprise Enhancement Goals

### 1. Real-Time Collaboration
- **Live Updates**: Comments appear instantly (Turbo Streams or WebSocket)
- **Presence Indicators**: Show who's online and viewing model
- **Cursor Sharing**: See where team members are looking (optional)
- **Live Annotations**: See markup as it's being created

### 2. Enhanced Comments
- **@Mentions**: Notify specific users
- **Rich Text**: Markdown support, images, links
- **Threads**: Reply to comments
- **Reactions**: 👍 👎 ✅ ❓ emojis
- **Status Tags**: Question, Issue, Suggestion, Resolved

### 3. Markup & Redlining
- **3D Annotations**: Text labels anchored to model
- **Sketches**: Freehand drawing on snapshots
- **Dimensioning**: Measurement annotations
- **Revision Clouds**: Highlight change areas
- **Symbols**: Standard markup symbols

### 4. Review Workflows
- **Design Reviews**: Scheduled review sessions
- **Sign-Off**: Approvals for design stages
- **Issue Tracking**: Track open issues to resolution
- **Review Reports**: Summary of feedback

---

## Proposed Architecture

### Layer 1: Real-Time Broadcasting

```ruby
# New: modules/bim/app/channels/bim/model_channel.rb
class Bim::ModelChannel < ApplicationCable::Channel
  def subscribed
    ifc_model = Bim::IFCModels::IFCModel.find(params[:model_id])
    stream_for ifc_model

    # Broadcast presence
    broadcast_presence('joined')
  end

  def unsubscribed
    broadcast_presence('left')
  end

  def receive(data)
    case data['type']
    when 'cursor_move'
      broadcast_cursor(data)
    when 'annotation_drawing'
      broadcast_annotation(data)
    end
  end

  private

  def broadcast_presence(action)
    Bim::ModelChannel.broadcast_to(
      ifc_model,
      type: 'presence',
      action: action,
      user: current_user.name,
      user_id: current_user.id
    )
  end

  def broadcast_cursor(data)
    Bim::ModelChannel.broadcast_to(
      ifc_model,
      type: 'cursor',
      user_id: current_user.id,
      position: data['position']
    )
  end
end

# Alternative: Use Turbo Streams (no WebSocket)
# Append comments via Turbo after create
class Bim::Bcf::CommentsController < ApplicationController
  def create
    # ... create comment ...

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "bcf_comments_#{@bcf_issue.id}",
          partial: 'bim/bcf/comments/comment',
          locals: { comment: @comment }
        )
      end
    end

    # Broadcast to all viewers
    broadcast_update_to @bcf_issue
  end

  private

  def broadcast_update_to(bcf_issue)
    Turbo::StreamsChannel.broadcast_append_to(
      "bcf_issue_#{bcf_issue.id}",
      target: "bcf_comments_#{bcf_issue.id}",
      partial: 'bim/bcf/comments/comment',
      locals: { comment: @comment }
    )
  end
end
```

### Layer 2: Mentions & Notifications

```ruby
# Enhanced: BCF Comment model
class Bim::Bcf::Comment < ApplicationRecord
  # ... existing associations ...

  has_many :mentions, class_name: 'Bim::CommentMention', dependent: :destroy
  has_many :mentioned_users, through: :mentions, source: :user

  after_create :notify_mentioned_users

  def parse_mentions!
    # Extract @username from comment text
    text = comment # Assuming comment field contains text

    mentions = text.scan(/@(\w+)/).flatten
    mentions.each do |username|
      user = User.find_by(login: username)
      self.mentions.create!(user: user) if user
    end
  end

  private

  def notify_mentioned_users
    mentioned_users.each do |user|
      OpenProject::Notifications.send(
        OpenProject::Events::BIM_COMMENT_MENTIONED,
        user: user,
        comment: self
      )
    end
  end
end

# New model
class Bim::CommentMention < ApplicationRecord
  belongs_to :comment, class_name: 'Bim::Bcf::Comment'
  belongs_to :user
end
```

### Layer 3: Database Schema

```sql
-- Comment mentions
CREATE TABLE bim_comment_mentions (
  id BIGSERIAL PRIMARY KEY,
  comment_id BIGINT NOT NULL REFERENCES bcf_comments(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_comment_mention UNIQUE (comment_id, user_id)
);

-- Presence tracking
CREATE TABLE bim_viewer_presence (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_seen_at TIMESTAMP NOT NULL,
  camera_position JSONB, -- Current view
  CONSTRAINT unique_presence UNIQUE (ifc_model_id, user_id)
);

CREATE INDEX idx_presence_model ON bim_viewer_presence(ifc_model_id);

-- Enhanced BCF comments (add columns)
ALTER TABLE bcf_comments
  ADD COLUMN status VARCHAR(50), -- 'question', 'issue', 'suggestion', 'resolved'
  ADD COLUMN reactions JSONB DEFAULT '{}'::jsonb; -- { "👍": [user_id1, user_id2], "✅": [user_id3] }
```

### Layer 4: Frontend Components

```typescript
// presence-indicator.component.ts
@Component({
  selector: 'op-presence-indicator',
  template: `
    <div class="presence-bar">
      <span *ngFor="let user of onlineUsers" class="user-avatar"
            [title]="user.name">
        {{ user.initials }}
      </span>
      <span class="count">{{ onlineUsers.length }} viewing</span>
    </div>
  `
})
export class PresenceIndicatorComponent implements OnInit {
  @Input() modelId: number;
  onlineUsers: User[] = [];

  ngOnInit() {
    // Subscribe to presence channel
    this.cable.subscribe(`Bim::ModelChannel::${this.modelId}`, {
      received: (data: any) => {
        if (data.type === 'presence') {
          if (data.action === 'joined') {
            this.onlineUsers.push({ id: data.user_id, name: data.user });
          } else {
            this.onlineUsers = this.onlineUsers.filter(u => u.id !== data.user_id);
          }
        }
      }
    });
  }
}

// enhanced-comment.component.ts
@Component({
  selector: 'op-enhanced-comment',
  template: `
    <div class="bim-comment">
      <div class="comment-header">
        <span class="author">{{ comment.author }}</span>
        <span class="timestamp">{{ comment.created_at | date }}</span>
        <span class="status-tag" [class]="comment.status">{{ comment.status }}</span>
      </div>

      <div class="comment-body" [innerHTML]="renderedMarkdown"></div>

      <div class="comment-reactions">
        <button *ngFor="let reaction of availableReactions"
                (click)="toggleReaction(reaction)"
                [class.active]="hasReacted(reaction)">
          {{ reaction }} {{ reactionCount(reaction) }}
        </button>
      </div>

      <div class="comment-actions">
        <button (click)="reply()">Reply</button>
        <button (click)="viewInModel()">View in 3D</button>
      </div>
    </div>
  `
})
export class EnhancedCommentComponent {
  @Input() comment: BcfComment;
  availableReactions = ['👍', '👎', '✅', '❓'];

  toggleReaction(emoji: string) {
    this.commentService.addReaction(this.comment.id, emoji).subscribe();
  }
}
```

---

## Demo Deliverables

**MVP Demo:**
1. User A opens model, User B joins → presence indicator shows "2 viewing"
2. User A adds comment with @UserC mention → UserC gets notification
3. User B adds reaction 👍 to comment → appears instantly
4. User A creates annotation on element → broadcasts to User B in real-time
5. Users export review report with all feedback

---

**Deliberation Complete** ✅
**Estimated LOC:** ~1,000 (Ruby: 500, TypeScript: 500)
**Estimated Duration:** 2 weeks
**Risk Level:** Medium (WebSocket/cable complexity)
