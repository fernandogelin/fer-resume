import type { TOC } from '@ember/component/template-only';
import type { Basics } from 'fer-resume/types/resume';
import { Card, CardContent } from 'fer-resume/components/ui/card';
import Person from 'fer-resume/components/person';
import ProfileLinks from 'fer-resume/components/profile-links';

interface ProfileCardSignature {
  Args: {
    person: Basics;
  };
  Blocks: {
    default: [];
  };
}

const ProfileCard: TOC<ProfileCardSignature> = <template>
  <Card @class="mb-4">
    <CardContent>
      <Person @person={{@person}} />
      <ProfileLinks @profiles={{@person.profiles}} />
    </CardContent>
  </Card>
  {{yield}}
</template>;

export default ProfileCard;
