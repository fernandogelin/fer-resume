"""Build compact, one-column resume PDFs from the localized JSON data."""
import json
from html import escape
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, KeepTogether, HRFlowable

ROOT = Path(__file__).resolve().parents[1]
FONT_DIR = Path('/System/Library/Fonts/Supplemental')
pdfmetrics.registerFont(TTFont('ArialResume', str(FONT_DIR / 'Arial.ttf')))
pdfmetrics.registerFont(TTFont('ArialResumeBold', str(FONT_DIR / 'Arial Bold.ttf')))
pdfmetrics.registerFontFamily('ArialResume', normal='ArialResume', bold='ArialResumeBold')
NAVY = colors.HexColor('#14283B')
SLATE = colors.HexColor('#3E5060')
BLUE = colors.HexColor('#186087')
LANGS = {
    'en': ('Experience', 'Education', 'Certification', 'Selected Publications', 'Expertise', 'Present'),
    'pt': ('Experiência', 'Formação', 'Certificação', 'Publicações Selecionadas', 'Competências', 'Atual'),
    'es': ('Experiencia', 'Formación', 'Certificación', 'Publicaciones Seleccionadas', 'Competencias', 'Actualidad'),
    'fr': ('Expérience', 'Formation', 'Certification', 'Publications Sélectionnées', 'Compétences', 'Aujourd’hui'),
}

styles = {
    'name': ParagraphStyle('name', fontName='ArialResumeBold', fontSize=18, leading=21, textColor=NAVY, spaceAfter=3),
    'title': ParagraphStyle('title', fontName='ArialResumeBold', fontSize=9.2, leading=12, textColor=BLUE, spaceAfter=4),
    'contact': ParagraphStyle('contact', fontName='ArialResume', fontSize=8.1, leading=11, textColor=SLATE, spaceAfter=6),
    'summary': ParagraphStyle('summary', fontName='ArialResume', fontSize=8.1, leading=10.8, textColor=NAVY, spaceAfter=5),
    'section': ParagraphStyle('section', fontName='ArialResumeBold', fontSize=9.1, leading=11, textColor=BLUE, spaceBefore=5, spaceAfter=2),
    'role': ParagraphStyle('role', fontName='ArialResumeBold', fontSize=8.3, leading=10, textColor=NAVY, spaceAfter=1),
    'meta': ParagraphStyle('meta', fontName='ArialResume', fontSize=7.6, leading=9, textColor=SLATE, spaceAfter=3),
    'bullet': ParagraphStyle('bullet', fontName='ArialResume', fontSize=7.7, leading=9.7, textColor=NAVY, leftIndent=9, firstLineIndent=-7, spaceAfter=1),
    'body': ParagraphStyle('body', fontName='ArialResume', fontSize=7.7, leading=9.7, textColor=NAVY, spaceAfter=2),
}

def paragraph(text, style, link=None):
    content = escape(text).replace('\n', '<br/>')
    if link:
        content = f'<link href="{escape(link, quote=True)}" color="#186087">{content}</link>'
    return Paragraph(content, styles[style])

def month(value, lang, present):
    if not value:
        return present
    y, m, _ = map(int, value.split('-'))
    months = {
        'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        'pt': ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'],
        'es': ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'],
        'fr': ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
    }
    return f'{months[lang][m - 1]} {y}'

def section(story, heading):
    story.append(paragraph(heading, 'section'))
    story.append(HRFlowable(width='100%', thickness=0.5, color=colors.HexColor('#C9D3DC'), spaceAfter=3))

def build(lang):
    data = json.loads((ROOT / 'app' / 'data' / f'resume-{lang}.json').read_text())
    labels = LANGS[lang]
    basics = data['basics']
    linkedin = next(p['url'] for p in basics['profiles'] if p['network'] == 'linkedin')
    github = next(p['url'] for p in basics['profiles'] if p['network'] == 'github')
    contact = f"{basics['location']}  |  {basics['email']}  |  {linkedin.removeprefix('https://')}  |  {github.removeprefix('https://')}"
    story = [paragraph(basics['name'], 'name'), paragraph(basics['label'], 'title'), paragraph(contact, 'contact'), paragraph(basics['summary'], 'summary')]
    section(story, labels[0])
    for work_index, work in enumerate(data['work']):
        heading = f"{work['position']}  |  {work['company']}"
        dates = f"{month(work['startDate'], lang, labels[5])} - {month(work['endDate'], lang, labels[5])}"
        if work['location']:
            dates += f"  |  {work['location']}"
        group = [paragraph(heading, 'role'), paragraph(dates, 'meta')]
        max_bullets = [4, 4, 2, 3, 2][work_index]
        group += [paragraph('• ' + item, 'bullet') for item in work['highlights'][:max_bullets]]
        group.append(Spacer(1, 2))
        story.append(KeepTogether(group))
    section(story, labels[1])
    for item in data['education']:
        story.append(paragraph(f"{item['studyType']} {item['area']}  |  {item['institution']}  |  {month(item['endDate'], lang, labels[5])}", 'body'))
    section(story, labels[2])
    for item in data['certifications']:
        story.append(paragraph(f"{item['studyType']} {item['area']}  |  {item['institution']}  |  {month(item['endDate'], lang, labels[5])}", 'body'))
    section(story, labels[3])
    for item in data['publications']:
        story.append(paragraph(f"{item['title']}  |  {item['journal']}, {item['year']}", 'body', item.get('url')))
    section(story, labels[4])
    for item in data['skills']:
        story.append(Paragraph(f"<b>{escape(item['name'])}</b>: {escape(', '.join(item['keywords']))}", styles['body']))

    output = ROOT / 'output' / 'pdf' / f'fernando-gelin-resume-{lang}.pdf'
    doc = SimpleDocTemplate(str(output), pagesize=A4, leftMargin=40, rightMargin=40, topMargin=30, bottomMargin=28, title=f"Fernando Gelin Resume ({lang})", author='Fernando Gelin')
    doc.build(story)
    (ROOT / 'public' / 'pdf' / output.name).write_bytes(output.read_bytes())
    print(output)

if __name__ == '__main__':
    for language in LANGS:
        build(language)
