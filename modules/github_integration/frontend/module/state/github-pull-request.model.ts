import {
  IHalResourceLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';
import { ID } from '@datorama/akita';

export interface ISnippet {
  id:string;
  name:string;
  textToDisplay:() => string;
  textToCopy:() => string
}

export interface IGithubUserResource {
  avatarUrl:string;
  htmlUrl:string;
  login:string;
}

export interface IGithubCheckRunResource {
  appOwnerAvatarUrl:string;
  completedAt:string;
  conclusion:string;
  detailsUrl:string;
  htmlUrl:string;
  name:string;
  outputSummary:string;
  outputTitle:string;
  startedAt:string;
  status:string;
}

export interface IGithubPullRequestResourceLinks extends IHalResourceLinks {
  githubUser:IHalResourceLink;
  mergedBy?:IHalResourceLink;
  checkRuns?:IHalResourceLink[];
}

export interface IGithubPullRequestResourceEmbedded {
  githubUser:IGithubUserResource;
  mergedBy?:IGithubUserResource;
  checkRuns:IGithubCheckRunResource[];
}

export interface IGithubPullRequest {
  id:ID;
  additionsCount?:number;
  body?:{
    format?:string;
    raw?:string;
    html?:string;
  },
  changedFilesCount?:number;
  commentsCount?:number;
  createdAt?:string;
  deletionsCount?:number;
  draft?:boolean;
  githubUpdatedAt?:string;
  htmlUrl:string;
  labels?:string[];
  merged?:boolean;
  mergedAt?:string;
  number?:number;
  repository:string;
  repositoryHtmlUrl:string;
  reviewCommentsCount?:number;
  state?:string;
  title:string;
  updatedAt?:string;

  _links:IGithubPullRequestResourceLinks;
  _embedded:IGithubPullRequestResourceEmbedded;
}
