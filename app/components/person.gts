import type { TOC } from '@ember/component/template-only';
import type { Basics } from 'fer-resume/types/resume';

interface PersonSignature {
  Args: {
    person: Basics;
  };
}

const Person: TOC<PersonSignature> = <template>
  <div class="mb-4">
    <h3 class="text-xl font-bold text-foreground">{{@person.name}}</h3>
    <p class="text-sm text-muted-foreground italic">{{@person.phonetic_name}}</p>
    <p class="text-sm font-medium text-primary">{{@person.label}}</p>
  </div>
</template>;

export default Person;
