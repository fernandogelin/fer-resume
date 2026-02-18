export interface Profile {
  network: string;
  username: string;
  url: string;
}

export interface Basics {
  name: string;
  phonetic_name: string;
  label: string;
  location: string;
  email: string;
  profiles: Profile[];
}

export interface WorkEntry {
  company: string;
  position: string;
  location: string;
  startDate: string;
  endDate: string | null;
  highlights: string[];
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

export interface Publication {
  title: string;
  journal: string;
  year: number;
  url?: string;
  authors: string;
}

export interface ResumeData {
  basics: Basics;
  work: WorkEntry[];
  education: EducationEntry[];
  skills: Skill[];
  publications: Publication[];
}
