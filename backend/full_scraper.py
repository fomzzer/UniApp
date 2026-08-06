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
    
    tables = soup.find_all('table')
    grades_table = None
    for tbl in tables:
        if "Дисциплина" in tbl.text:
            grades_table = tbl
            break

    if not grades_table:
        return []

    for tr in grades_table.find_all('tr')[1:]:
        tds = tr.find_all('td')
        if not tds:
            continue
            
        first_td = tds[0]
        b_tag = first_td.find('b')
        
        if not b_tag:
            continue
            
        subject_name = b_tag.text.strip()
        full_text = first_td.get_text(separator=' ', strip=True)
        
        type_match = re.search(r'\((.*?)\)', full_text.replace(subject_name, ''))
        control_type = type_match.group(1) if type_match else ""
        
        grade_matches = re.findall(r'([А-Яа-я\.\s]+\(\d\))\s*\((редовна|поправителна)\)', full_text)
        
        regular_grade = "-"
        retake_grade = "-"
        final_grade = "-"
        
        if "Зачита се" in full_text:
            regular_grade = "Зачита се"
            final_grade = "Зачита се"
            
        for grade_val, try_type in grade_matches:
            grade_val = grade_val.strip()
            if try_type == 'редовна':
                regular_grade = grade_val
                final_grade = grade_val
            elif try_type == 'поправителна':
                retake_grade = grade_val
                final_grade = grade_val
                
        grades_list.append({
            "subject": subject_name,
            "type": control_type,
            "regular": regular_grade,
            "retake": retake_grade,
            "final": final_grade
        })
        
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
                        
                    logger.info(f"Attempt {attempt + 1}: AI CAPTCHA processed: {captcha_text}")

            data = {
                'fnum': credentials.faculty_no,
                'captcha': captcha_text
            }

            if is_2fa:
                data['d_f_i'] = credentials.auth_code
            else:
                data['egn'] = credentials.auth_code

            post_response = session.post(url, headers=headers, data=data, timeout=10)

            if "Изход" in post_response.text:
                soup = BeautifulSoup(post_response.text, 'lxml')
                logout_btn = soup.find('input', id='izh')

                if logout_btn:
                    full_name = logout_btn.parent.text.strip()
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
                    grades_link = soup.find('a', string=re.compile(r"Заверки и оценки"))
                    
                    if grades_link and 'href' in grades_link.attrs:
                        grades_url = urljoin(url, grades_link['href'])
                        grades_response = session.get(grades_url, headers=headers, timeout=10)
                        grades_soup = BeautifulSoup(grades_response.text, 'lxml')
                        
                        student_grades = parse_grades(grades_soup)
                    else:
                        logger.error("Не удалось найти ссылку на оценки на главной странице")

                    return {
                        'status': 'success',
                        'name': full_name,
                        'info': all_info,
                        'grades': student_grades
                    }
                else:
                    return {'status': 'error', 'message': "Failed to parse information"}
            
            if is_2fa:
                break
            
            logger.warning("Login failed, retrying with new CAPTCHA...")
            time.sleep(0.5)

        return {'status': 'error', 'message': "Invalid credentials or CAPTCHA"}

    except Exception as e:
        logger.error(f"Request error: {e}")
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

                soup = BeautifulSoup(response.text, 'html.parser')
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
                logger.error(f"Error with {faculty_id}: {e}")
                continue

        return all_schedules
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))