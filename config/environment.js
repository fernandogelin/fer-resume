"use strict";

module.exports = function(environment) {
  let ENV = {
    modulePrefix: "fer-resume",
    environment,
    rootURL: "/",
    locationType: "auto",
    i18nextOptions: {
      lowerCaseLng: true,
      fallbackLng: "en-se",
      whitelist: ["en-se", "pt-br"]
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
      "font-src": ["'self'"],
      "connect-src": ["'self'", "https://api.github.com"],
      "img-src": ["'self'"],
      "style-src": ["'self'"],
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
