import Route from '@ember/routing/route';
import type { ResumeData } from 'fer-resume/types/resume';

export default class IndexRoute extends Route {
  model(): ResumeData {
    return this.modelFor('application') as ResumeData;
  }
}
