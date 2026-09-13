# Collaboration Enhancement Feature

## Overview

The Collaboration Enhancement feature adds real-time collaboration capabilities to BIM comments, including @mentions, emoji reactions, viewer presence tracking, and enhanced comment statuses. This enables teams to communicate more effectively during model review and coordination workflows.

## Key Features

### 1. @Mentions in Comments
- **User Tagging**: Mention team members using `@username` syntax
- **Automatic Detection**: System automatically parses and creates mention records
- **Notifications**: Mentioned users receive notifications
- **Mention Tracking**: View all comments where you were mentioned

### 2. Comment Reactions
- **Emoji Reactions**: Add emoji reactions to comments (👍 👎 ✅ ❓ ❤️ 🎉 🚀 👀)
- **Toggle Support**: Click to add/remove your reaction
- **User Attribution**: See who reacted with each emoji
- **Real-Time Updates**: Reactions update via Turbo Streams

### 3. Viewer Presence
- **Active Viewers**: See who's currently viewing a model
- **Presence Indicators**: Avatar-based presence display
- **Camera Tracking**: Optionally track where users are looking
- **Auto-Cleanup**: Stale presence records automatically removed

### 4. Comment Status Tags
- **Structured Status**: Assign status to comments (question, issue, suggestion, resolved, info)
- **Visual Indicators**: Status-based color coding
- **Filtering**: Filter comments by status
- **Workflow Support**: Track comment resolution

## Database Schema

### Tables

#### `bim_comment_mentions`
Tracks user mentions in BCF comments.

```sql
CREATE TABLE bim_comment_mentions (
  id BIGSERIAL PRIMARY KEY,
  comment_id BIGINT NOT NULL REFERENCES bcf_comments(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_comment_mention UNIQUE (comment_id, user_id)
);

CREATE INDEX idx_comment_mentions_comment ON bim_comment_mentions(comment_id);
CREATE INDEX idx_comment_mentions_user ON bim_comment_mentions(user_id);
```

#### `bim_viewer_presence`
Tracks who's actively viewing IFC models.

```sql
CREATE TABLE bim_viewer_presence (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES bim_ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_seen_at TIMESTAMP NOT NULL,
  camera_position JSONB,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  CONSTRAINT unique_presence UNIQUE (ifc_model_id, user_id)
);

CREATE INDEX idx_presence_model ON bim_viewer_presence(ifc_model_id);
CREATE INDEX idx_presence_last_seen ON bim_viewer_presence(last_seen_at);
```

#### Enhanced `bcf_comments`
Added columns to existing table.

```sql
ALTER TABLE bcf_comments
  ADD COLUMN status VARCHAR(50),
  ADD COLUMN reactions JSONB DEFAULT '{}' NOT NULL;

CREATE INDEX idx_bcf_comments_status ON bcf_comments(status);
CREATE INDEX idx_bcf_comments_reactions ON bcf_comments USING GIN (reactions);

ALTER TABLE bcf_comments
  ADD CONSTRAINT check_bcf_comment_status
  CHECK (status IS NULL OR status IN ('question', 'issue', 'suggestion', 'resolved', 'info'));
```

### Comment Status Values

| Status     | Description                              | Use Case                |
|------------|------------------------------------------|-------------------------|
| question   | Question requiring answer                | Seeking clarification   |
| issue      | Problem that needs resolution            | Clash or error found    |
| suggestion | Improvement suggestion                   | Design optimization     |
| resolved   | Issue has been resolved                  | Problem fixed           |
| info       | Informational update                     | Status update           |

### Reactions JSONB Format

```json
{
  "👍": [user_id1, user_id2],
  "✅": [user_id3],
  "🎉": [user_id1, user_id3, user_id4]
}
```

## API Reference

### Comment Reactions

#### Get Reactions
```http
GET /api/v3/bim/comments/:comment_id/reactions
```

**Response:**
```json
{
  "_type": "CommentReactions",
  "comment_id": 123,
  "reactions": [
    {
      "emoji": "👍",
      "count": 3,
      "users": [
        {"id": 1, "name": "Alice Architect", "login": "architect"},
        {"id": 2, "name": "Bob Engineer", "login": "engineer"}
      ]
    }
  ],
  "allowed_reactions": ["👍", "👎", "✅", "❓", "❤️", "🎉", "🚀", "👀"]
}
```

#### Add Reaction
```http
POST /api/v3/bim/comments/:comment_id/reactions
Content-Type: application/json

{
  "emoji": "👍"
}
```

#### Toggle Reaction
```http
POST /api/v3/bim/comments/:comment_id/reactions/toggle
Content-Type: application/json

{
  "emoji": "👍"
}
```

#### Remove Reaction
```http
DELETE /api/v3/bim/comments/:comment_id/reactions
Content-Type: application/json

{
  "emoji": "👍"
}
```

### Viewer Presence

#### Get Active Viewers
```http
GET /api/v3/bim/ifc_models/:ifc_model_id/presence
```

**Response:**
```json
{
  "_type": "ViewerPresence",
  "ifc_model_id": 456,
  "active_viewers_count": 3,
  "viewers": [
    {
      "id": 1,
      "name": "Alice Architect",
      "login": "architect",
      "initials": "AA"
    }
  ]
}
```

#### Join Viewing Session
```http
POST /api/v3/bim/ifc_models/:ifc_model_id/presence
Content-Type: application/json

{
  "camera_position": {
    "eye": [10, 10, 10],
    "look": [0, 0, 0],
    "up": [0, 1, 0]
  }
}
```

#### Update Presence (Heartbeat)
```http
PUT /api/v3/bim/ifc_models/:ifc_model_id/presence
Content-Type: application/json

{
  "camera_position": {
    "eye": [5, 5, 5],
    "look": [0, 0, 0],
    "up": [0, 1, 0]
  }
}
```

#### Leave Viewing Session
```http
DELETE /api/v3/bim/ifc_models/:ifc_model_id/presence
```

### Comment Mentions

#### Get My Mentions
```http
GET /api/v3/bim/comment_mentions
```

#### Get Mentions in Comment
```http
GET /api/v3/bim/comment_mentions/:comment_id
```

## Backend Usage

### Working with Mentions

```ruby
# Parse mentions from comment (automatic via callback)
comment = Bim::Bcf::Comment.create!(
  journal: journal,
  issue: bcf_issue
)
# Mentions are automatically parsed from journal.notes

# Get mentioned users
comment.mentioned_users # => [User, User, ...]

# Find all comments where a user was mentioned
Bim::CommentMention.mentioned_comments_for_user(user)

# Find all users mentioned in a comment
Bim::CommentMention.mentioned_users_in_comment(comment)
```

### Working with Reactions

```ruby
comment = Bim::Bcf::Comment.find(123)

# Add a reaction
comment.add_reaction('👍', user.id)

# Remove a reaction
comment.remove_reaction('👍', user.id)

# Toggle a reaction
comment.toggle_reaction('👍', user.id)

# Get reaction count
comment.reaction_count('👍') # => 3

# Check if user reacted
comment.user_reacted?('👍', user.id) # => true/false

# Get reactions summary with user details
comment.reactions_summary
# => [
#   {
#     emoji: '👍',
#     count: 3,
#     users: [{id: 1, name: 'Alice', login: 'alice'}, ...]
#   }
# ]

# Using the service
service = Bim::Collaboration::ReactionService.new(comment)
service.toggle_reaction(emoji: '👍', user: current_user)
```

### Working with Presence

```ruby
# Update presence
service = Bim::Collaboration::PresenceService.new(ifc_model)
service.update_presence(
  user: current_user,
  camera_position: { eye: [1, 2, 3], look: [0, 0, 0], up: [0, 1, 0] }
)

# Get active viewers
service.active_viewers # => [User, User, ...]
service.active_viewers_count # => 3

# Check if specific user is viewing
service.user_viewing?(user) # => true/false

# Get presence summary for broadcasting
service.presence_summary
# => {
#   total_viewers: 3,
#   viewers: [{id: 1, name: 'Alice', login: 'alice', initials: 'AA'}, ...]
# }

# Cleanup stale presence (run via cron/scheduled job)
Bim::Collaboration::PresenceService.cleanup_stale(1.hour.ago)
```

### Working with Comment Status

```ruby
comment = Bim::Bcf::Comment.find(123)

# Set status
comment.update(status: 'question')

# Check status
comment.question? # => true
comment.issue? # => false
comment.resolved? # => false

# Filter comments by status
Bim::Bcf::Comment.where(status: 'question')
Bim::Bcf::Comment.where(status: ['issue', 'question'])
```

## Frontend Usage

### Presence Indicator Component

```html
<op-presence-indicator
  [ifcModelId]="modelId"
  [getCameraPosition]="getCameraFn">
</op-presence-indicator>
```

```typescript
export class ViewerComponent {
  modelId = 123;

  getCameraFn = () => {
    // Return current camera position from your viewer
    return {
      eye: this.viewer.camera.eye,
      look: this.viewer.camera.look,
      up: this.viewer.camera.up
    };
  };
}
```

### Comment Reactions Component

```html
<op-comment-reactions
  [commentId]="comment.id"
  [currentUserId]="currentUser.id">
</op-comment-reactions>
```

### Presence Service

```typescript
import { PresenceService } from './collaboration/presence.service';

constructor(private presenceService: PresenceService) {}

// Join viewing session
this.presenceService.joinViewing(modelId, cameraPosition).subscribe();

// Start heartbeat (auto-updates every 30s)
this.presenceService.startPresenceHeartbeat(
  modelId,
  () => this.getCameraPosition()
).subscribe();

// Leave viewing session
this.presenceService.leaveViewing(modelId).subscribe();

// Poll for presence updates
this.presenceService.pollPresence(modelId, 10000).subscribe(presence => {
  console.log(`${presence.active_viewers_count} users viewing`);
});
```

### Comment Reactions Service

```typescript
import { CommentReactionsService } from './collaboration/comment-reactions.service';

constructor(private reactionsService: CommentReactionsService) {}

// Toggle reaction
this.reactionsService.toggleReaction(commentId, '👍').subscribe();

// Get reactions
this.reactionsService.getReactions(commentId).subscribe(data => {
  console.log(`Total reactions: ${this.reactionsService.getTotalCount(data.reactions)}`);
});
```

## Demo Data

Generate demo collaboration data:

```bash
rails runner modules/bim/db/seeds/collaboration_demo_data.rb
```

This creates:
- 4 demo users (architect, engineer, coordinator, admin)
- 1 IFC model
- 1 work package with BCF issue
- 4 BCF comments with:
  - 5 mentions across comments
  - 13 reactions total
  - Various statuses (question, issue, resolved, info)
  - Comment threading (replies)
- 4 viewer presence records

## Testing

### Run Model Tests

```bash
bundle exec rspec modules/bim/spec/models/bim/comment_mention_spec.rb
bundle exec rspec modules/bim/spec/models/bim/viewer_presence_spec.rb
```

### Using Factories

```ruby
# Create mention
mention = create(:bim_comment_mention, user: user, comment: comment)

# Create active presence
presence = create(:bim_viewer_presence, :active, ifc_model: model, user: user)

# Create comment with reactions
comment = create(:bcf_comment_with_reactions, :with_many_reactions)
```

## Best Practices

### 1. Mentions
- **Clear References**: Use mentions sparingly and purposefully
- **Notification Fatigue**: Avoid over-mentioning to prevent notification spam
- **Context**: Provide context when mentioning users

### 2. Reactions
- **Emoji Consistency**: Use standard reactions for team consistency
- **Professional Use**: Keep reactions professional and constructive
- **Substitute for Comments**: Use reactions for quick acknowledgment

### 3. Presence
- **Privacy**: Camera position tracking is optional
- **Performance**: Heartbeat every 30s balances real-time vs server load
- **Cleanup**: Run `cleanup_stale` job hourly to remove inactive presence

### 4. Comment Status
- **Lifecycle**: Use status to track comment lifecycle (question → issue → resolved)
- **Filtering**: Leverage status for workflow management
- **Consistency**: Establish team conventions for status usage

## Performance Considerations

### Database
- Mentions indexed on both comment_id and user_id
- Presence indexed on ifc_model_id and last_seen_at
- Reactions use GIN index for efficient JSONB queries
- Unique constraints prevent duplicate mentions/presence

### API
- Presence polling recommended at 10-30 second intervals
- Heartbeat updates every 30 seconds
- Reactions use toggle endpoint to minimize requests

### Frontend
- Presence component uses RxJS for efficient polling
- Reactions component updates optimistically
- Stale presence automatically cleaned up server-side

## Troubleshooting

### Mentions Not Working

**Problem**: Users not receiving mention notifications

**Solutions**:
1. Check that username is correct (case-sensitive)
2. Verify NotificationService is properly configured
3. Check user's email preferences
4. Review journal.notes for proper @username format

### Presence Not Updating

**Problem**: Viewer count not updating

**Solutions**:
1. Check heartbeat subscription is active
2. Verify API endpoints are accessible
3. Check for JavaScript console errors
4. Ensure presence polling interval isn't too long

### Reactions Not Saving

**Problem**: Reactions don't persist

**Solutions**:
1. Verify emoji is in ALLOWED_REACTIONS list
2. Check user has permission to view comment
3. Review API response for errors
4. Check reactions JSONB column exists

## Future Enhancements

- **Real-Time WebSockets**: Upgrade from polling to ActionCable for true real-time
- **Rich Notifications**: Email and in-app notifications for mentions
- **Mention Autocomplete**: Typeahead suggestions when typing @
- **Cursor Sharing**: Show where other users are looking in 3D viewer
- **Comment Threads**: Enhanced threading UI
- **Reaction Analytics**: Track reaction patterns and engagement

## Related Features

- **BCF Comments** (Core): Foundation for collaboration
- **3D Viewer** (Slice 2): Provides viewpoint context
- **Element Linking** (Slice 3): Links comments to specific elements
- **IFC Upload** (Slice 1): Provides models for viewing

## Support

For issues or questions:
- GitHub Issues: https://github.com/opf/openproject/issues
- Documentation: https://www.openproject.org/docs/bim/
- Community Forums: https://community.openproject.org/
