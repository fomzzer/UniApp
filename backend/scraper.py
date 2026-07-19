import requests
from bs4 import BeautifulSoup
import json
import os
import time

def fetch_all_schedules():

    url = "https://tu-sofia.bg/university/weeklyprograms"
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

    all_schedules = []

    for faculty_id in range(1, 35):
        print(f"Faculty ID {faculty_id}...", end="", flush=True)

        form_data = {
            "Faculty[id]": str(faculty_id)
        }

        try:
            response = requests.post(url, headers=headers, data=form_data)
            if response.status_code != 200:
                print(" ошибка сервера")
                continue

            soup = BeautifulSoup(response.text, 'html.parser')

            all_tables = soup.find_all('table')

            valid_tables = [t for t in all_tables if "Специалност" in t.text and "Поток" in t.text]

            if not valid_tables:
                print(" пусто")
                continue

            count = 0

            for idx, table in enumerate(valid_tables):

                if "Няма намерени резултати" in table.text:
                    continue

                rows = table.find_all('tr')[1:]

                for row in rows:
                    cols = row.find_all('td')
                    if len(cols) >= 7:
                        faculty = cols[2].text.strip()
                        specialty = cols[3].text.strip()
                        course = cols[4].text.strip()
                        stream = cols[5].text.strip()

                        link_tag = cols[6].find('a')
                        if link_tag and 'href' in link_tag.attrs:
                            pdf_url = link_tag['href']
                            if pdf_url.startswith('/'):
                                pdf_url = "https://tu-sofia.bg" + pdf_url

                            all_schedules.append({
                                "faculty": faculty,
                                "specialty": specialty,
                                "course": course,
                                "stream": stream,
                                "url": pdf_url
                            })
                            count += 1

            time.sleep(0.5)

        except Exception as e:
            print(f" ошибка: {e}")
            continue

    script_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(script_dir, "schedules.json")

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(all_schedules, f, ensure_ascii=False, indent=4)


if __name__ == "__main__":
    fetch_all_schedules()