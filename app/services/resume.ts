import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import type { ResumeData } from 'fer-resume/types/resume';
import resumeEn from 'fer-resume/data/resume-en.json';
import resumePt from 'fer-resume/data/resume-pt.json';
import resumeEs from 'fer-resume/data/resume-es.json';
import resumeFr from 'fer-resume/data/resume-fr.json';

const RESUME_DATA: Record<string, ResumeData> = {
  'en-se': resumeEn as ResumeData,
  'pt-br': resumePt as ResumeData,
  es: resumeEs as ResumeData,
  fr: resumeFr as ResumeData,
};

export default class ResumeService extends Service {
  @tracked locale = 'en-se';

  get data(): ResumeData {
    return RESUME_DATA[this.locale] ?? (RESUME_DATA['en-se'] as ResumeData);
  }

  setLocale(locale: string): void {
    this.locale = locale;
  }
}

declare module '@ember/service' {
  interface Registry {
    resume: ResumeService;
  }
}
