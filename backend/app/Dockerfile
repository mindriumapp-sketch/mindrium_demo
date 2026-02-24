FROM python:3.11-slim

WORKDIR /app

# (필요시) 빌드 도구
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
  && rm -rf /var/lib/apt/lists/*

# requirements 설치
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# 소스 복사
COPY . /app

EXPOSE 8000

# main.py 안에 FastAPI 인스턴스 이름이 app 라는 전제 (일반적)
CMD ["bash", "-lc", "python -m uvicorn main:app --host 0.0.0.0 --port 8000"]
