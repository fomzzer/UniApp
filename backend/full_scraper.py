from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests
from bs4 import BeautifulSoup
import time
import logging
import ddddocr
import re
from urllib.parse import urljoin

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()
ocr = ddddocr.DdddOcr(show_ad=False)

class LoginData(BaseModel):
    faculty_no: str
    auth_code: str

def parse_grades(soup):
    grades_list = []
    
    grades_table = None
    for tbl in soup.find_all('table'):
        text = tbl.get_text().lower()
        if "дисциплина" in text and "лекции" in text:
            grades_table = tbl
            break
            
    if not grades_table:
        logger.warning("Target grades table ('дисциплина', 'лекции') not found in the DOM.")
        return []
        
    for tr in grades_table.find_all('tr')[1:]:
        tds = tr.find_all('td')
        if not tds:
            continue
            
        first_td = tds[0]
        full_text = first_td.get_text(separator=' ', strip=True)
        
        if "(" not in full_text and "зачита се" not in full_text.lower():
            continue
            
        subject_name = full_text.split('(')[0].strip()
        if not subject_name:
            continue
            
        if "сем." in subject_name.lower() and len(subject_name) < 15:
            continue
            
        type_match = re.search(r'\((.*?)\)', full_text)
        control_type = type_match.group(1).strip() if type_match else ""
        
        regular_grade = "-"
        retake_grade = "-"
        final_grade = "-"
        
        if "зачита се" in full_text.lower():
            regular_grade = "Зачита се"
            final_grade = "Зачита се"
        else:
            grade_matches = re.findall(r'((?:Слаб|Среден|Добър|Мн\.\s*добър|Отличен)\s*\(\d\))\s*\((редовна|поправителна)\)', full_text, re.IGNORECASE)
            
            for grade_val, try_type in grade_matches:
                grade_val = grade_val.strip()
                if try_type.lower() == 'редовна':
                    regular_grade = grade_val
                    final_grade = grade_val
                elif try_type.lower() == 'поправителна':
                    retake_grade = grade_val
                    final_grade = grade_val
                    
        if control_type or final_grade != "-":
            grades_list.append({
                "subject": subject_name,
                "type": control_type,
                "regular": regular_grade,
                "retake": retake_grade,
                "final": final_grade
            })
            
    if not grades_list:
        logger.error("Grades table identified, but record extraction yielded no results. DOM snapshot follows:")
        logger.error(grades_table.prettify()[:2000])
        
    return grades_list


@app.post("/api/login")
def get_info(credentials: LoginData):
    url = "https://e-university.tu-sofia.bg/ETUS/studenti/"
    headers = {"User-Agent": "Mozilla/5.0"}

    is_2fa = len(credentials.auth_code) == 6 and credentials.auth_code.isdigit()
    max_attempts = 1 if is_2fa else 7 

    session = requests.Session()

    try:
        for attempt in range(max_attempts):
            session.get(url, headers=headers, timeout=10)

            captcha_text = ""
            
            if not is_2fa:
                captcha_url = "https://e-university.tu-sofia.bg/ETUS/studenti/captcha.php"
                captcha_response = session.get(captcha_url, headers=headers, timeout=10)
                
                if captcha_response.status_code == 200:
                    raw_captcha = ocr.classification(captcha_response.content)
                    captcha_text = raw_captcha.strip().upper()
                    
                    replacements = {'0':'O', '1':'I', '2':'Z', '3':'E', '4':'A', '5':'S', '6':'G', '7':'T', '8':'B', '9':'G'}
                    for digit, letter in replacements.items():
                        captcha_text = captcha_text.replace(digit, letter)
                        
                    logger.info(f"Authentication attempt {attempt + 1}: CAPTCHA resolved as '{captcha_text}'.")

            data = {
                'fnum': credentials.faculty_no,
                'captcha': captcha_text
            }

            if is_2fa:
                data['d_f_i'] = credentials.auth_code
            else:
                data['egn'] = credentials.auth_code

            post_response = session.post(url, headers=headers, data=data, timeout=10)
            post_response.encoding = 'utf-8'

            soup = BeautifulSoup(post_response.text, 'lxml')
            logout_btn = soup.find('input', id='izh')

            if logout_btn:
                full_name = logout_btn.parent.get_text(strip=True)
                all_info = {}
                info_table = soup.find('table', id='info')

                if info_table:
                    for row in info_table.find_all('tr'):
                        cells = row.find_all('td')

                        for i in range(0, len(cells) - 1, 2):
                            key_element = cells[i]
                            val_element = cells[i+1]

                            key_strings = list(key_element.stripped_strings)
                            key = key_strings[0].replace('\xa0', ' ').replace('"', '').strip().rstrip(':').strip() if key_strings else ""

                            val_strings = list(val_element.stripped_strings)
                            val = val_strings[0].replace('"', '').strip() if val_strings else ""

                            if key:
                                all_info[key] = val
                
                student_grades = []
                form_data = {}
                nav_form = soup.find('form', attrs={'name': 'nav'})
                action_url = url
                
                if nav_form:
                    if nav_form.get('action'):
                        action_url = urljoin(url, nav_form.get('action'))
                    for inp in nav_form.find_all('input'):
                        name = inp.get('name') or inp.get('id')
                        if name:
                            form_data[name] = inp.get('value', '')
                else:
                    for inp in soup.find_all('input', type='hidden'):
                        name = inp.get('name') or inp.get('id')
                        if name:
                            form_data[name] = inp.get('value', '')

                form_data['deistvie'] = '1'
                
                grades_response = session.post(action_url, headers=headers, data=form_data, timeout=10)
                grades_response.encoding = 'utf-8'
                grades_soup = BeautifulSoup(grades_response.text, 'lxml')
                
                student_grades = parse_grades(grades_soup)

                return {
                    'status': 'success',
                    'name': full_name,
                    'info': all_info,
                    'grades': student_grades
                }
            
            if is_2fa:
                break
            
            logger.warning("Authentication unsuccessful. Retrying with a new CAPTCHA challenge...")
            time.sleep(0.5)

        return {'status': 'error', 'message': "Invalid credentials or CAPTCHA"}

    except Exception as e:
        logger.error(f"Session request failed due to exception: {e}")
        return {'status': 'error', 'message': f"Server connection error: {str(e)}"}


@app.get("/api/schedules")
def get_schedule():
    try:
        url = "https://tu-sofia.bg/university/weeklyprograms"
        headers = {"User-Agent": "Mozilla/5.0"}

        all_schedules = []

        for faculty_id in range(1, 35):
            form_data = {
                "Faculty[id]": str(faculty_id)
            }

            try:
                response = requests.post(url, headers=headers, data=form_data)
                if response.status_code != 200:
                    continue
                
                response.encoding = 'utf-8'
                soup = BeautifulSoup(response.text, 'lxml')
                all_tables = soup.find_all('table')
                valid_tables = [t for t in all_tables if "Специалност" in t.text and "Поток" in t.text]

                if not valid_tables:
                    continue

                for i, table in enumerate(valid_tables):
                    if "Няма намерени резултати" in table.text:
                        continue

                    rows = table.find_all('tr')[1:]

                    for row in rows:
                        cols = row.find_all('td')
                        if len(cols) >= 7:
                            faculty = cols[2].text.strip()
                            speciality = cols[3].text.strip()
                            course = cols[4].text.strip()
                            stream = cols[5].text.strip()

                            link_tag = cols[6].find('a')
                            if link_tag and 'href' in link_tag.attrs:
                                pdf_url = link_tag['href']
                                if pdf_url.startswith('/'):
                                    pdf_url = "https://tu-sofia.bg" + pdf_url

                                all_schedules.append({
                                    "faculty": faculty,
                                    "speciality": speciality,
                                    "course": course,
                                    "stream": stream,
                                    "url": pdf_url
                                })

                time.sleep(0.5)

            except Exception as e:
                logger.error(f"Schedule retrieval failed for faculty ID {faculty_id}. Exception: {e}")
                continue

        return all_schedules
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))