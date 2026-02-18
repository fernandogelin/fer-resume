import EmberRouter from '@embroider/router';
import config from 'fer-resume/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('projects');
  this.route('project', { path: '/project/:project_id' });
});
