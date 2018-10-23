FROM python:3.7.0-alpine3.8
COPY . /app
WORKDIR /app
RUN pip install flask
ENTRYPOINT ["python3"]
CMD ["main.py"]
