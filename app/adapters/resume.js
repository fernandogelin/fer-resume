import RESTAdapter from '@ember-data/adapter/rest';

export default class ResumeAdapter extends RESTAdapter {
  headers() {
    return {
      ACCEPT: 'application/vnd.github.v3+json'
    };
  }

  pathForType() {
    return 'gists';
  }

  host = 'https://api.github.com';
}
