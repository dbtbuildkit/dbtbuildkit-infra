FROM python:3.12-slim
LABEL authors="AriHenrique"

RUN apt-get update -y && apt-get install -y \
    git \
    gh \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

ENV PATH="/usr/local/bin:$PATH"
ENV PYTHONWARNINGS="ignore::UserWarning"

COPY dbt-kit /tmp/dbt-kit
RUN if head -1 /tmp/dbt-kit | grep -q "version https://git-lfs"; then \
        echo "ERROR: dbt-kit is a Git LFS pointer, not a real binary!" && \
        echo "Run 'git lfs pull' before building the Docker image" && \
        exit 1; \
    fi && \
    cp /tmp/dbt-kit /usr/local/bin/dbt-kit && \
    chmod +x /usr/local/bin/dbt-kit && \
    rm /tmp/dbt-kit && \
    echo "dbt-kit binary installed successfully"

WORKDIR /usr/src/app

RUN pip install poetry "setuptools<81"
COPY . ./
RUN poetry config virtualenvs.create false && poetry install --no-root

CMD ["python", "--version"]
