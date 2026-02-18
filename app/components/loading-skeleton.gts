import type { TOC } from '@ember/component/template-only';
import { Skeleton } from 'fer-resume/components/ui/skeleton';

const LoadingSkeleton: TOC<object> = <template>
  <div class="grid grid-cols-1 md:grid-cols-[300px_1fr] gap-6 p-6 max-w-5xl mx-auto">
    <aside>
      <div class="space-y-3">
        <Skeleton @class="h-6 w-3/4" />
        <Skeleton @class="h-4 w-1/2" />
        <Skeleton @class="h-4 w-2/3" />
        <Skeleton @class="h-20 w-full mt-4" />
      </div>
    </aside>
    <main>
      <div class="space-y-4">
        <Skeleton @class="h-8 w-1/3" />
        <Skeleton @class="h-4 w-full" />
        <Skeleton @class="h-4 w-5/6" />
        <Skeleton @class="h-4 w-4/5" />
        <Skeleton @class="h-8 w-1/3 mt-6" />
        <Skeleton @class="h-4 w-full" />
        <Skeleton @class="h-4 w-5/6" />
      </div>
    </main>
  </div>
</template>;

export default LoadingSkeleton;
