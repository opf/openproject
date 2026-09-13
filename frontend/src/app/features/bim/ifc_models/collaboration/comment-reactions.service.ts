import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ReactionSummary {
  emoji: string;
  count: number;
  users: Array<{
    id: number;
    name: string;
    login: string;
  }>;
}

export interface CommentReactions {
  comment_id: number;
  reactions: ReactionSummary[];
  allowed_reactions: string[];
}

@Injectable({
  providedIn: 'root'
})
export class CommentReactionsService {
  // Default allowed reactions
  readonly ALLOWED_REACTIONS = ['👍', '👎', '✅', '❓', '❤️', '🎉', '🚀', '👀'];

  constructor(private http: HttpClient) {}

  /**
   * Get all reactions for a comment
   */
  getReactions(commentId: number): Observable<CommentReactions> {
    return this.http.get<CommentReactions>(
      `/api/v3/bim/comments/${commentId}/reactions`
    );
  }

  /**
   * Add a reaction to a comment
   */
  addReaction(commentId: number, emoji: string): Observable<any> {
    return this.http.post(
      `/api/v3/bim/comments/${commentId}/reactions`,
      { emoji }
    );
  }

  /**
   * Toggle a reaction (add if not present, remove if present)
   */
  toggleReaction(commentId: number, emoji: string): Observable<any> {
    return this.http.post(
      `/api/v3/bim/comments/${commentId}/reactions/toggle`,
      { emoji }
    );
  }

  /**
   * Remove a reaction from a comment
   */
  removeReaction(commentId: number, emoji: string): Observable<any> {
    return this.http.delete(
      `/api/v3/bim/comments/${commentId}/reactions`,
      { body: { emoji } }
    );
  }

  /**
   * Check if current user has reacted
   */
  hasUserReacted(reaction: ReactionSummary, userId: number): boolean {
    return reaction.users.some(u => u.id === userId);
  }

  /**
   * Get total reaction count for a comment
   */
  getTotalCount(reactions: ReactionSummary[]): number {
    return reactions.reduce((sum, r) => sum + r.count, 0);
  }
}
