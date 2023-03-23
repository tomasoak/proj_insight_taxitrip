import os
import requests
from datetime import datetime

from airflow.decorators import dag, task

args = {'owner': 'Tomas'}

@dag(
    dag_id='main-dag',
    default_args=args,
    start_date=datetime(2023, 3, 18),
    schedule_interval='@daily',
)

def elt():

    @task(task_id="extract")
    def extracts():
        url = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/fhv/fhv_tripdata_"

        def download_raw_data(url: str, year: int, month: int):
            raw_data = requests.get(f"{url}{year}-{month:02}.csv.gz", stream=True)

            with open(f"gcs/data/fvh_tripdata_{year}-{month:02}.csv.gz", 'wb') as f:
                for chunk in raw_data.raw.stream(1024, decode_content=False):
                    if chunk:
                        f.write(chunk)

        for year in range(2019, 2022):
            if year == 2021:
                for month in range(1, 8):
                    download_raw_data(url, year, month)
            else:
                for month in range(1, 13):
                    download_raw_data(url, year, month)

    extracts()

elt()

