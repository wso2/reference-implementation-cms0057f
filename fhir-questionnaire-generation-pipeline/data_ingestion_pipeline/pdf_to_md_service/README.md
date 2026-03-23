# PDF to Markdown Conversion Service

A FastAPI-based microservice that converts PDF documents to Markdown format using [**Docling**](https://docling-project.github.io/docling/). The service supports both FTP and local file storage, processes conversions asynchronously, and sends notifications upon completion.

---

## Features

- **Asynchronous PDF-to-Markdown Conversion**: Background processing using FastAPI's BackgroundTasks
- **Flexible Storage Options**: 
  - FTP server integration for remote file storage
  - Local file system storage for development/testing
- **Automatic Notifications**: HTTP callback to notify downstream services when conversion completes
- **Health Monitoring**: Built-in health check endpoint
- **Input Validation**: Pydantic-based request validation

---

## API Endpoints

| Method   | Endpoint   | Description                                                                    | Request Body                               |
| -------- | ---------- | ------------------------------------------------------------------------------ | ------------------------------------------ |
| **POST** | `/convert` | Initiates PDF-to-Markdown conversion. Returns immediately with job status.     | `{"job_id": "string", "file_name": "string"}` |
| **GET**  | `/health`  | Health check endpoint to verify the service is running.                        | None                                       |

### POST /convert

**Request Example:**
```json
{
  "job_id": "job-12345",
  "file_name": "document-name"
}
```

**Response Example:**
```json
{
  "job_id": "job-12345",
  "filename": "document-name",
  "status": "started",
  "message": "File uploaded successfully. Processing started."
}
```

**Notes:**
- The `file_name` should be provided **without** the `.pdf` extension
- Processing happens in the background; use notifications to track completion
- PDF files are read from `/pdf` directory (FTP) or `{LOCAL_DIR}/pdf` (local storage)
- Converted Markdown files are stored in `/md` directory (FTP) or `{LOCAL_DIR}/md` (local storage)

---

## Configuration

Configure the service using environment variables in a `.env` file:

### Storage Mode

```sh
# Set to true for FTP storage, false for local file system
USE_FTP=false
```

### FTP Configuration (when USE_FTP=true)

```sh
FTP_HOST=127.0.0.1
FTP_PORT=2121
FTP_USERNAME=ftp_user
FTP_PASSWORD=ftp_password
```

### Local Storage Configuration (when USE_FTP=false)

```sh
# Relative or absolute path to data directory
LOCAL_DIR=../../data/
```

### Notification Configuration

```sh
# Callback URL to receive conversion status notifications
NOTIFICATION_CALLBACK_URL=http://localhost:6080/notification
```

**Notification Payload:**
```json
{
  "job_id": "job-12345",
  "file_name": "document-name",
  "status": "completed|failed",
  "message": "pdf_to_md_done|conversion_failed|storage_failed"
}
```

---

## Setup Instructions

### Prerequisites

- Python 3.12 or higher
- [uv](https://github.com/astral-sh/uv) package manager

### Installation

1. **Navigate** to the service directory:
   ```bash
   cd data_ingestion_pipeline/pdf_to_md_service
   ```

2. **Create** a `.env` file with your configuration:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Install** dependencies:
   ```bash
   uv sync
   ```

4. **Prepare storage directories** (for local storage mode):
   ```bash
   mkdir -p ../../data/pdf ../../data/md
   ```

5. **Run** the service:
   ```bash
   uv run main.py
   ```

6. The service will be available at:
   **`http://0.0.0.0:8000`**

7. **Access API documentation** at:
   - Swagger UI: `http://0.0.0.0:8000/docs`
   - ReDoc: `http://0.0.0.0:8000/redoc`

---

## Architecture

### Workflow

1. Client sends POST request to `/convert` with `job_id` and `file_name`
2. Service validates request and immediately returns 202 response
3. Background task begins:
   - Reads PDF from FTP server or local storage (`/pdf` directory)
   - Converts PDF to Markdown using Docling
   - Stores Markdown in FTP server or local storage (`/md` directory)
   - Sends notification to configured callback URL
4. Temporary files are cleaned up automatically

### File Structure

```
pdf_to_md_service/
├── main.py              # FastAPI application and endpoints
├── models.py            # Pydantic request/response models
├── settings.py          # Configuration management
├── utils.py             # Core conversion and notification logic
├── ftp_utils.py         # FTP-specific file operations
├── file_utils.py        # Local file system operations
├── requirements.txt     # Dependencies (alternative to pyproject.toml)
├── pyproject.toml       # Project metadata and dependencies
└── .env                 # Environment variables (create from template)
```
