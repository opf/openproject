export type JobStatusEnum = 'in_queue'|'error'|'in_process'|'success'|'failure'|'cancelled';

export interface JobStatusInterface {
  /**
   * Status
   */
  status:JobStatusEnum;

  /**
   * The job id
   */
  jobId:string;

  /**
   * Message for the current status, if any
   */
  message?:string;

  /**
   * Additional payload object
   */
  payload?:{
    title?:string;
    download?:string;
    redirect?:string;
  };
}
