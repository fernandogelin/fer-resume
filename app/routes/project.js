import Route from '@ember/routing/route';

export default class ProjectRoute extends Route {
  model(params) {
    return this.modelFor('application').projects
      .filter(project => project.id == params.project_id)[0]
  }
}
