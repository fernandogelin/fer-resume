import RESTAdapter from "@ember-data/adapter/rest";
import { computed } from "@ember/object";

export default class ApplicationAdapter extends RESTAdapter {
  @computed
  get headers() {
    return {
      ACCEPT: "application/vnd.github.v3+json"
    };
  }

  host = "https://api.github.com";
}
