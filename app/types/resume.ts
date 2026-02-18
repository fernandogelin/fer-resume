export interface Profile {
  network: string;
  username: string;
  url: string;
}

export interface Basics {
  name: string;
  phonetic_name: string;
  label: string;
  profiles: Profile[];
}

export interface WorkEntry {
  company: string;
  position: string;
  startDate: string;
  endDate: string | null;
  summary: string;
}

export interface EducationEntry {
  institution: string;
  area: string;
  studyType: string;
  startDate: string;
  endDate: string | null;
  thesis?: string;
}

export interface Skill {
  name: string;
  keywords: string[];
}

export interface Project {
  id: string;
  name: string;
  description: string;
  labels: string[];
  repo?: string;
  url?: string;
  preview?: string;
}

export interface ResumeData {
  basics: Basics;
  work: WorkEntry[];
  education: EducationEntry[];
  skills: Skill[];
  projects: Project[];
}
