import type { TOC } from '@ember/component/template-only';
import type { Basics } from 'fer-resume/types/resume';
import { on } from '@ember/modifier';
import { t } from 'ember-intl';
import { Volume2 } from 'lucide-static';
import Icon from 'fer-resume/components/icon';

interface PersonSignature {
  Args: {
    person: Basics;
  };
}

const playPronunciation = async (event: Event): Promise<void> => {
  const button = event.currentTarget as HTMLButtonElement;
  const audio = button.parentElement?.querySelector('audio');
  if (!audio) return;
  audio.currentTime = 0;
  try {
    await audio.play();
  } catch {
    audio.hidden = false;
    audio.controls = true;
  }
};

const Person: TOC<PersonSignature> = <template>
  <div class="mb-4">
    <div class="flex flex-wrap items-center gap-2">
      <h3 class="text-xl font-bold text-foreground">{{@person.name}}</h3>
      <button
        type="button"
        class="inline-flex rounded-full p-2 text-muted-foreground hover:text-primary focus-visible:outline-2 focus-visible:outline-ring print:hidden"
        aria-label={{t "actions.pronounce_name"}}
        title={{t "actions.pronounce_name"}}
        {{on "click" playPronunciation}}
      >
        <Icon @svg={{Volume2}} @size={{16}} aria-hidden="true" />
      </button>
      <audio
        hidden
        preload="none"
        src="/audio/fernando-gelin.wav"
        aria-label={{t "actions.pronounce_name"}}
        class="max-w-full print:hidden"
      ></audio>
    </div>
    <p class="text-sm text-muted-foreground">{{@person.phonetic_name}}</p>
    {{#if @person.pronunciation_english}}
      <p class="text-xs text-muted-foreground" lang="en">
        {{@person.pronunciation_english}}
      </p>
    {{/if}}
    <p class="text-sm font-medium text-primary">{{@person.label}}</p>
  </div>
</template>;

export default Person;
