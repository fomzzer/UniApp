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

            return {
                'status': 'success',
                'name': full_name
            }
        else:
            return {'status': 'error', 'message': "Failed to parse name"}
    else:
        return {'status': 'error', 'message': "Invalid credentials"}
