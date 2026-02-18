import Controller from '@ember/controller';
import { type Registry as Services, service } from '@ember/service';
import { action } from '@ember/object';

export default class ApplicationController extends Controller {
  @service declare intl: Services['intl'];
  @service declare router: Services['router'];
  @service declare resume: Services['resume'];

  get currentLocale(): string {
    return this.intl.primaryLocale ?? 'en-se';
  }

  @action
  switchLocale(event: Event): void {
    const target = event.target as HTMLSelectElement;
    const locale = target.value;
    this.intl.setLocale([locale, 'en-se']);
    this.resume.setLocale(locale);
    this.router.refresh();
  }

  @action
  async downloadPdf(): Promise<void> {
    const content = document.querySelector('.resume-content');
    if (!content) return;

    const { default: html2pdf } = await import('html2pdf.js');
    const name = this.resume.data.basics.name.toLowerCase().replace(/\s+/g, '-');
    const label = this.resume.data.basics.label.toLowerCase().replace(/\s+/g, '-');

    await html2pdf()
      .set({
        margin: [10, 10, 10, 10],
        filename: `${name}-${label}-resume.pdf`,
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2, useCORS: true },
        jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
        pagebreak: { mode: ['avoid-all', 'css', 'legacy'] },
      })
      .from(content as HTMLElement)
      .save();
  }
}
