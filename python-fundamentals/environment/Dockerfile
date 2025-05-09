FROM python:latest

WORKDIR /app

# copy the requirements and install them
COPY requirements.txt . 

RUN pip install --upgrade pip && pip install -r requirements.txt 

# Keep container running for interactive development
# Command to keep the container running
CMD ["python"]