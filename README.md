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

**If deploy fails with "Request to ... firebaseextensions.googleapis.com ... had HTTP Error: 403"**

The deploy service account needs permission to call the Firebase Extensions API. A project **Owner** should:

1. Open [IAM & Admin](https://console.cloud.google.com/iam-admin/iam?project=fer-resume).
2. Edit the deploy principal (same as above) and add the role **Firebase Extensions API Viewer** (or a role that includes `firebaseextensions.instances.list`).

If that role is not available, ensure the [Firebase Extensions API](https://console.cloud.google.com/apis/library/firebaseextensions.googleapis.com?project=fer-resume) is enabled for the project and the deploy account has a role that can list extension instances.

**If deploy reports "Unable to set the invoker for the IAM policy"**

The `apiProxy` function is configured with `invoker: 'public'` in code so it is created as publicly invokable (needed for Hosting rewrites). If the error persists, the deploy account may need **Cloud Functions Admin** (`roles/functions.admin`); **Cloud Functions Developer** alone cannot change IAM policies.

**Cleanup policy (optional)**  
To reduce artifact storage cost, run once: `npx firebase-tools functions:artifacts:setpolicy --project fer-resume` or deploy with `--force` (already used in CI).

## Further Reading / Useful Links

* [ember.js](https://emberjs.com/)
* [ember-cli](https://ember-cli.com/)
* Development Browser Extensions
  * [ember inspector for chrome](https://chrome.google.com/webstore/detail/ember-inspector/bmdblncegkenkacieihfhpjfppoconhi)
  * [ember inspector for firefox](https://addons.mozilla.org/en-US/firefox/addon/ember-inspector/)
