import EmberRouter from "@ember/routing/router";
import config from "./config/environment";
import I18nMixin from "ember-i18next/mixins/i18n";

export default class Router extends EmberRouter.extend(I18nMixin) {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function() {
  this.route("resume");
});
