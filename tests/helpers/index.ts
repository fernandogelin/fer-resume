import {
  setupApplicationTest as upstreamSetupApplicationTest,
  setupRenderingTest as upstreamSetupRenderingTest,
  setupTest as upstreamSetupTest,
  type SetupTestOptions,
} from 'ember-qunit';
import translationsForEnSe from 'virtual:ember-intl/translations/en-se';
import translationsForPtBr from 'virtual:ember-intl/translations/pt-br';

interface IntlTestService {
  addTranslations: (locale: string, translations: unknown) => void;
  setLocale: (locales: string[]) => void;
}

interface OwnerWithLookup {
  lookup: (name: 'service:intl') => IntlTestService;
}

function setupIntl(hooks: NestedHooks) {
  hooks.beforeEach(function () {
    const intl = (this as unknown as { owner: OwnerWithLookup }).owner.lookup('service:intl');
    intl.addTranslations('en-se', translationsForEnSe);
    intl.addTranslations('pt-br', translationsForPtBr);
    intl.setLocale(['en-se']);
  });
}

function setupApplicationTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupApplicationTest(hooks, options);
  setupIntl(hooks);
}

function setupRenderingTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupRenderingTest(hooks, options);
  setupIntl(hooks);
}

function setupTest(hooks: NestedHooks, options?: SetupTestOptions) {
  upstreamSetupTest(hooks, options);
  setupIntl(hooks);
}

export { setupApplicationTest, setupRenderingTest, setupTest };
