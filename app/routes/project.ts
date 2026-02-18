import Route from '@ember/routing/route';
import type { ResumeData, Project } from 'fer-resume/types/resume';

export default class ProjectRoute extends Route {
  model(params: { project_id: string }): Project | undefined {
    const appModel = this.modelFor('application') as ResumeData;
    return appModel.projects.find(
      (project) => project.id === params.project_id,
    );
  }
}
