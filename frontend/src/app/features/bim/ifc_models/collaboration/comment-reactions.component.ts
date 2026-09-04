import { Component, Input, OnInit } from '@angular/core';
import { CommentReactionsService, ReactionSummary } from './comment-reactions.service';

@Component({
  selector: 'op-comment-reactions',
  templateUrl: './comment-reactions.component.html',
  styleUrls: ['./comment-reactions.component.sass']
})
export class CommentReactionsComponent implements OnInit {
  @Input() commentId!: number;
  @Input() currentUserId?: number;

  reactions: ReactionSummary[] = [];
  allowedReactions: string[] = [];
  showPicker = false;
  loading = true;

  constructor(private reactionsService: CommentReactionsService) {
    this.allowedReactions = this.reactionsService.ALLOWED_REACTIONS;
  }

  ngOnInit(): void {
    if (!this.commentId) {
      console.error('Comment ID is required for reactions');
      this.loading = false;
      return;
    }

    this.loadReactions();
  }

  loadReactions(): void {
    this.reactionsService.getReactions(this.commentId).subscribe({
      next: (data) => {
        this.reactions = data.reactions || [];
        this.loading = false;
      },
      error: (err) => {
        console.error('Failed to load reactions:', err);
        this.loading = false;
      }
    });
  }

  toggleReaction(emoji: string): void {
    this.reactionsService.toggleReaction(this.commentId, emoji).subscribe({
      next: (response) => {
        this.reactions = response.reactions || [];
        this.showPicker = false;
      },
      error: (err) => {
        console.error('Failed to toggle reaction:', err);
      }
    });
  }

  hasUserReacted(reaction: ReactionSummary): boolean {
    if (!this.currentUserId) return false;
    return this.reactionsService.hasUserReacted(reaction, this.currentUserId);
  }

  togglePicker(): void {
    this.showPicker = !this.showPicker;
  }

  getTotalCount(): number {
    return this.reactionsService.getTotalCount(this.reactions);
  }

  getUserNames(reaction: ReactionSummary): string {
    return reaction.users.map(u => u.name).join(', ');
  }
}
