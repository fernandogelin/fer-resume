import type { TOC } from '@ember/component/template-only';
import type { Basics } from 'fer-resume/types/resume';
import { Card, CardContent } from 'fer-resume/components/ui/card';
import Person from 'fer-resume/components/person';
import ProfileLinks from 'fer-resume/components/profile-links';
import Icon from 'fer-resume/components/icon';
import { MapPin, Mail } from 'lucide-static';

interface ProfileCardSignature {
  Args: {
    person: Basics;
  };
}

const ProfileCard: TOC<ProfileCardSignature> = <template>
  <Card @class="mb-4">
    <CardContent>
      <Person @person={{@person}} />
      <div class="flex flex-col gap-1 mt-2 text-sm text-muted-foreground">
        <span class="flex items-center gap-2">
          <Icon @svg={{MapPin}} @size={{14}} />
          {{@person.location}}
        </span>
        <a href="mailto:{{@person.email}}" class="flex items-center gap-2">
          <Icon @svg={{Mail}} @size={{14}} />
          {{@person.email}}
        </a>
      </div>
      <ProfileLinks @profiles={{@person.profiles}} />
    </CardContent>
  </Card>
</template>;

export default ProfileCard;
