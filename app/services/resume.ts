import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import type { ResumeData } from 'fer-resume/types/resume';

const GIST_API = 'https://api.github.com/gists';

const RESUME_IDS: Record<string, string> = {
  'en-se': 'fbc7c5a8630ee55274ec7ee89f62dd5f',
  'pt-br': 'da99c3da93c806d4d6319279c844ad72',
};

interface GistResponse {
  files: {
    'resume.json': {
      content: string;
    };
  };
}

export default class ResumeService extends Service {
  @tracked data: ResumeData | null = null;
  @tracked isLoading = false;
  @tracked error: string | null = null;

  private cache = new Map<string, ResumeData>();

  async load(locale: string): Promise<ResumeData> {
    const cached = this.cache.get(locale);
    if (cached) {
      this.data = cached;
      return cached;
    }

    const gistId = RESUME_IDS[locale] ?? RESUME_IDS['en-se']!;

    this.isLoading = true;
    this.error = null;

    try {
      const response = await fetch(`${GIST_API}/${gistId}`, {
        headers: {
          Accept: 'application/vnd.github.v3+json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch resume: ${response.statusText}`);
      }

      const gist = (await response.json()) as GistResponse;
      const resume = JSON.parse(
        gist.files['resume.json'].content,
      ) as ResumeData;

      this.cache.set(locale, resume);
      this.data = resume;
      return resume;
    } catch (e) {
      this.error = e instanceof Error ? e.message : 'Unknown error';
      throw e;
    } finally {
      this.isLoading = false;
    }
  }
}

declare module '@ember/service' {
  interface Registry {
    resume: ResumeService;
  }
}
