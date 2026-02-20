# fer-resume

This README outlines the details of collaborating on this Ember application.
A short introduction of this app could easily go here.

## Prerequisites

You will need the following things properly installed on your computer.

* [Git](https://git-scm.com/)
* [Node.js](https://nodejs.org/) (with npm)
* [Ember CLI](https://ember-cli.com/)
* [Google Chrome](https://google.com/chrome/)

## Installation

* `git clone <repository-url>` this repository
* `cd fer-resume`
* `npm install`

## Running / Development

* `ember serve`
* Visit your app at [http://localhost:4200](http://localhost:4200).
* Visit your tests at [http://localhost:4200/tests](http://localhost:4200/tests).

### Code Generators

Make use of the many generators for code, try `ember help generate` for more details

### Running Tests

* `ember test`
* `ember test --server`

### Linting

* `npm run lint:hbs`
* `npm run lint:js`
* `npm run lint:js -- --fix`

### Building

* `ember build` (development)
* `ember build --environment production` (production)

### Deploying

The app deploys to **Firebase Hosting** (and Cloud Functions for the Ocean Live API proxy) on push to `main` via GitHub Actions.

**If Functions deploy fails with "Missing permissions... iam.serviceAccounts.ActAs"**

The service account used in CI must be allowed to act as the default App Engine service account. A project **Owner** should:

1. Open [IAM & Admin](https://console.cloud.google.com/iam-admin/iam?project=fer-resume) for the `fer-resume` project.
2. Find the principal used for deploy (the `client_email` from the `FIREBASE_SERVICE_ACCOUNT_FER_RESUME` secret).
3. Edit that principal and add the role **Service Account User** (so it has `iam.serviceAccounts.ActAs` on `fer-resume@appspot.gserviceaccount.com`).

Alternatively, grant **Service Account User** at the project level to the deploy service account.

## Further Reading / Useful Links

* [ember.js](https://emberjs.com/)
* [ember-cli](https://ember-cli.com/)
* Development Browser Extensions
  * [ember inspector for chrome](https://chrome.google.com/webstore/detail/ember-inspector/bmdblncegkenkacieihfhpjfppoconhi)
  * [ember inspector for firefox](https://addons.mozilla.org/en-US/firefox/addon/ember-inspector/)
