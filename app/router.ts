import EmberRouter from '@embroider/router';
import config from 'fer-resume/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  // index route is implicit
  this.route('projects', function () {
    this.route('seat-map');
    this.route('seat-map-benchmark');
    this.route('earthquake-visualizer');
  });
});
