import { pageTitle } from 'ember-page-title';
import ProfileCard from 'fer-resume/components/profile-card';
import SkillsSection from 'fer-resume/components/skills-section';
import LocaleSwitcher from 'fer-resume/components/locale-switcher';
import Icon from 'fer-resume/components/icon';
import { FileDown } from 'lucide-static';
import { t } from 'ember-intl';

<template>
  {{pageTitle "Fernando Gelin"}}

  <header class="border-b border-border bg-card/50 backdrop-blur-sm sticky top-0 z-10">
    <div class="flex items-center justify-between px-4 md:px-6 py-2 max-w-5xl mx-auto">
      <a
        href="assets/pdf/fernando-gelin-senior-software-engineer-resume.pdf"
        download
        class="inline-flex items-center gap-2 text-sm font-medium text-primary hover:text-primary/80 transition-colors"
      >
        <Icon @svg={{FileDown}} @size={{16}} />
        {{t "actions.download"}}
      </a>
      <LocaleSwitcher
        @currentLocale={{@controller.currentLocale}}
        @onSwitch={{@controller.switchLocale}}
      />
    </div>
  </header>

  <div class="grid grid-cols-1 md:grid-cols-[300px_1fr] gap-6 p-4 md:p-6 max-w-5xl mx-auto min-h-screen">
    <aside class="space-y-4">
      <ProfileCard @person={{@model.basics}} />
      <SkillsSection @skills={{@model.skills}} />
    </aside>
    <main>
      {{outlet}}
    </main>
  </div>
</template>
