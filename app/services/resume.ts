import Service from '@ember/service';
import type { ResumeData } from 'fer-resume/types/resume';
import resumeEn from 'fer-resume/data/resume-en.json';

export default class ResumeService extends Service {
  get data(): ResumeData {
    return resumeEn as ResumeData;
  }
}

declare module '@ember/service' {
  interface Registry {
    resume: ResumeService;
  }
}
