"use strict";

module.exports = function(environment) {
  let ENV = {
    modulePrefix: "fer-resume",
    environment,
    rootURL: "/",
    locationType: "auto",
    'ember-local-storage': {
      includeEmberDataSupport: true
    },
    EmberENV: {
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. EMBER_NATIVE_DECORATOR_SUPPORT: true
      },
      EXTEND_PROTOTYPES: {
        // Prevent Ember Data from overriding Date.parse.
        Date: false
      }
    },

    resumeIDs: {
      'en-se': 'fbc7c5a8630ee55274ec7ee89f62dd5f',
      'en-us': 'fbc7c5a8630ee55274ec7ee89f62dd5f',
      'pt-br': 'da99c3da93c806d4d6319279c844ad72'
    },

    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
    },
    contentSecurityPolicyHeader: "Content-Security-Policy",
    contentSecurityPolicyMeta: true,
    contentSecurityPolicy: {
      "default-src": ["'none'"],
      "script-src": ["'self'"],
      "frame-src": ["'self'"],
      "font-src": ["'self'", " https://use.typekit.net"],
      "connect-src": ["'self'", "https://api.github.com"],
      "img-src": ["'self'"],
      "style-src": [
        "'self'",
        " https://use.typekit.net/ojh0dfq.css",
        "https://p.typekit.net/p.css?s=1&k=ojh0dfq&ht=tk&f=28031.30222.30223&a=8261510&app=typekit&e=css "
      ],
      "media-src": ["'self'"],
      "manifest-src": ["'self'"]
    }
  };

  // Unsafe script eval and inline is necessary in
  // development and test environments
  const enableUnsafeCSP = () => {
    ENV.contentSecurityPolicy["script-src"].push("'unsafe-eval'");
    ENV.contentSecurityPolicy["style-src"].push("'unsafe-inline'");
  };

  if (environment === "development") {
    // ENV.APP.LOG_RESOLVER = true;
    // ENV.APP.LOG_ACTIVE_GENERATION = true;
    // ENV.APP.LOG_TRANSITIONS = true;
    // ENV.APP.LOG_TRANSITIONS_INTERNAL = true;
    // ENV.APP.LOG_VIEW_LOOKUPS = true;

    ENV["ember-a11y-testing"] = {
      componentOptions: {
        axeOptions: {
          checks: {
            "color-contrast": { options: { noScroll: true } }
          }
        }
      }
    };

    enableUnsafeCSP();
  }

  if (environment === "test") {
    // Testem prefers this...
    ENV.locationType = "none";

    // keep test console output quieter
    ENV.APP.LOG_ACTIVE_GENERATION = false;
    ENV.APP.LOG_VIEW_LOOKUPS = false;

    ENV.APP.rootElement = "#ember-testing";
    ENV.APP.autoboot = false;

    // CSP will break test coverage, so it is disabled
    ENV.contentSecurityPolicyMeta = false;
  }

  if (environment === "production") {
    // here you can enable a production-specific feature
  }

  return ENV;
};
