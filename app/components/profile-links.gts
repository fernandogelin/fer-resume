import type { TOC } from '@ember/component/template-only';
import type { Profile } from 'fer-resume/types/resume';
import Icon from 'fer-resume/components/icon';
import { Github, Linkedin, Globe } from 'lucide-static';

function iconForNetwork(network: string): string {
  const lower = network.toLowerCase();
  if (lower === 'github') return Github;
  if (lower === 'linkedin') return Linkedin;
  return Globe;
}

interface ProfileLinksSignature {
  Args: {
    profiles: Profile[];
  };
}

const ProfileLinks: TOC<ProfileLinksSignature> = <template>
  <div class="flex flex-col gap-2">
    {{#each @profiles as |profile|}}
      <a
        href={{profile.url}}
        aria-label={{profile.network}}
        class="flex items-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
        target="_blank"
        rel="noopener noreferrer"
      >
        <Icon @svg={{iconForNetwork profile.network}} @size={{16}} />
        <span>{{profile.username}}</span>
      </a>
    {{/each}}
  </div>
</template>;

export default ProfileLinks;
