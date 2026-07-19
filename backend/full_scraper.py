from fastapi import FastAPI
from pydantic import BaseModel
import requests
from bs4 import BeautifulSoup

app = FastAPI()

class LoginData(BaseModel):
    faculty_no: str
    auth_code: str

@app.post("/api/login")
def scrap_tu_sofia(credentials: LoginData):
    url = "https://e-university.tu-sofia.bg/ETUS/studenti/"
    headers = {"User-Agent": "Mozilla/5.0"}

    data = {
        'fnum': credentials.faculty_no,
        'd_f_i': credentials.auth_code
    }

    session = requests.Session()
    post_response = session.post(url, headers=headers, data=data)

    if "Изход" in post_response.text:
        soup = BeautifulSoup(post_response.text, 'lxml')
        logout_btn = soup.find('input', id = 'izh')

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

                        key = key_element.text.replace('\xa0', ' ').strip().rstrip(':').strip()
                        val_strings = list(val_element.stripped_strings)
                        val = val_strings[0].replace('"', '') if val_strings else ""

                        if key:
                            all_info[key] = val

            return {
                'status': 'success',
                'name': full_name,
                'info': all_info
            }
        else:
            return {'status': 'error', 'message': "Failed to parse information"}
    else:
        return {'status': 'error', 'message': "Invalid credentials"}
