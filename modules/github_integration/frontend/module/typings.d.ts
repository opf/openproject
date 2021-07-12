import { HalResourceClass } from 'core-app/modules/hal/resources/hal-resource';

export interface ISnippet {
  id:string;
  name:string;
  textToCopy:() => string
}

export interface IGithubPullRequestResource extends HalResourceClass {
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
  htmlUrl?:string;
  id?:number;
  labels?:string[];
  merged?:boolean;
  mergedAt?:string;
  mergedBy?:IGithubUserResource;
  number?:number;
  repository?:string;
  reviewCommentsCount?:number;
  state?:string;
  title?:string;
  updatedAt?:string;
  githubUser?:IGithubUserResource;
  checkRuns?:IGithubCheckRunResource[];
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
