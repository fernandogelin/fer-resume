import Route from '@ember/routing/route';

export default class ProjectsRoute extends Route {
  model() {
    return this.modelFor('application')
  }
}
