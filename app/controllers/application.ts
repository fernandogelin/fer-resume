import Controller from '@ember/controller';
import { type Registry as Services, service } from '@ember/service';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class ApplicationController extends Controller {
  @service declare intl: Services['intl'];
  @service declare router: Services['router'];
  @service declare resume: Services['resume'];

  @tracked localeOverride: string | null = null;

  get currentLocale(): string {
    return this.localeOverride ?? this.intl.primaryLocale ?? 'en-se';
  }

  get isResumeRoute(): boolean {
    return this.router.isActive('index');
  }

  @action
  setLocale(locale: string): void {
    this.localeOverride = locale;
    this.intl.setLocale([locale, 'en-se']);
    this.resume.setLocale(locale);
    this.router.refresh();
  }

  @action
  switchLocale(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.setLocale(target.value);
  }

  @action
  downloadPdf(): void {
    const locale =
      this.currentLocale === 'en-se'
        ? 'en'
        : this.currentLocale === 'pt-br'
          ? 'pt'
          : this.currentLocale;
    const link = document.createElement('a');
    link.href = `/pdf/fernando-gelin-resume-${locale}.pdf`;
    link.download = `fernando-gelin-resume-${locale}.pdf`;
    document.body.append(link);
    link.click();
    link.remove();
  }
}
