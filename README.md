---
title: DOCent
emoji: 📚
colorFrom: purple
colorTo: pink
sdk: docker
app_port: 7860
pinned: false
---

# DOCent

**AI-Powered Document Question Answering System**

Upload PDFs, DOCX, or text files and query them through a streaming chat interface powered by RAG (Retrieval-Augmented Generation).

## Tech Stack

- **Backend**: Python 3.11 · FastAPI (async) · SQLAlchemy + aiosqlite
- **Frontend**: React 18 · Vite · inline styles (no CSS framework)
- **AI**: Google Gemini — `gemini-3-flash-preview` (generation) · `gemini-embedding-001` (embeddings)
- **Vector Store**: ChromaDB (persistent HNSW index, cosine similarity)
- **Relational Store**: SQLite — document metadata, query history

---

## Setup

### Prerequisites

- Python 3.11+
- Node.js 18+
- A [Google AI Studio](https://aistudio.google.com/app/apikey) API key (free tier)

### 1. Backend

```bash
cd backend
python3.11 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Create .env
echo "GEMINI_API_KEY=your_key_here" > .env

uvicorn main:app --reload --port 8000
```

### 2. Frontend

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173)

### Quick start (both servers at once)

```bash
./start.sh
```

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/documents` | Upload a document (multipart: `title`, `file`) |
| `GET` | `/documents` | List all documents |
| `GET` | `/documents/{id}` | Get document detail + chunk count |
| `DELETE` | `/documents/{id}` | Delete document and its vectors |
| `POST` | `/documents/{id}/summary` | Generate or fetch summary + keywords |
| `POST` | `/documents/query` | RAG query (non-streaming) |
| `POST` | `/workflow/query` | Multi-step workflow query (`stream: true` for SSE) |
| `GET` | `/history` | Fetch query history |
| `DELETE` | `/history/{id}` | Delete a history entry |

### Upload a document

```bash
curl -X POST http://localhost:8000/documents \
  -F "title=Research Paper" \
  -F "file=@paper.pdf"
```

### Workflow query (streaming)

```bash
curl -X POST http://localhost:8000/workflow/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What are the main findings?", "stream": true}'
```

### RAG query (non-streaming)

```bash
curl -X POST http://localhost:8000/documents/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Summarize section 2", "document_id": "optional-uuid"}'
```

---

## Architecture

```
┌────────────────────────────────────────────────────┐
│                   React Frontend                    │
│   Sidebar (docs + history) │ Chat (streaming SSE)  │
└───────────────────┬────────────────────────────────┘
                    │ HTTP / SSE
┌───────────────────▼────────────────────────────────┐
│                  FastAPI Backend                    │
│                                                     │
│  POST /documents                                    │
│    └─► Extract text (PDF / DOCX / TXT / MD)        │
│    └─► Chunk (500 words, 50-word overlap)           │
│    └─► Embed with Gemini (gemini-embedding-001)     │
│    └─► Store vectors in ChromaDB (HNSW index)      │
│    └─► Store metadata in SQLite                     │
│                                                     │
│  POST /workflow/query  (4-step pipeline)            │
│    Step 1 – Analyze query → intent + keywords       │
│    Step 2 – ChromaDB ANN search → top-K chunks      │
│    Step 3 – Gemini generation with retrieved context│
│    Step 4 – Structure output: sources, confidence   │
│                                                     │
│  POST /documents/{id}/summary  (on-demand)          │
│    └─► Gemini summarization + keyword extraction    │
│                                                     │
│  GET /history ──► SQLite QueryHistory               │
└───────────────────┬────────────────────────────────┘
                    │
        ┌───────────┴────────────┐
        │                        │
┌───────▼──────┐      ┌──────────▼──────────┐
│   ChromaDB   │      │   Google Gemini API  │
│  HNSW index  │      │  embedding + generation│
│ cosine space │      └─────────────────────┘
└──────────────┘
```

### Multi-step Workflow

| Step | Name | Description |
|------|------|-------------|
| 1 | Analyze Query | Classify intent (question / summary / comparison / definition) and extract search keywords |
| 2 | Retrieve Context | ChromaDB approximate nearest-neighbor search over embedded chunks |
| 3 | Generate Response | Gemini generates an answer using retrieved chunks as context, streamed via SSE |
| 4 | Structure Output | Attach source citations, relevance scores, and confidence rating |

### Confidence Score

Derived from the top chunk's cosine similarity, scaled to 0–100%.
Green ≥ 70% · Yellow 40–70% · Red < 40%.

### Vector Storage

Chunks are embedded once at upload time and stored in a persistent ChromaDB collection (`./chroma_db/`) with cosine distance as the metric. At query time, the query is embedded and the HNSW index returns the top-K nearest chunks without a full scan — efficient even as the document set grows.

---

## Supported File Types

| Format | Notes |
|--------|-------|
| `.pdf` | Text-layer PDFs (scanned images are not OCR'd) |
| `.docx` | Paragraph text extracted |
| `.txt` / `.md` | Plain text, read as UTF-8 |

---

## Design Decisions

- **Deferred LLM calls on upload** — Keywords and summaries are generated on-demand (`POST /documents/{id}/summary`), not during upload, to avoid hitting Gemini's free-tier rate limits while chunking and embedding.
- **Word-based chunking** — 500-word chunks with 50-word overlap. Simple, effective, and avoids tokenizer dependencies.
- **ChromaDB over in-memory scan** — Persistent HNSW index means vectors survive server restarts and query latency stays flat as the corpus grows.
- **SSE streaming** — The workflow endpoint streams tokens as they arrive from Gemini, giving a real-time typing effect in the UI.
- **No authentication** — Single-user local tool, consistent with the problem scope.

## Bonus Features

- [x] Streaming responses via Server-Sent Events
- [x] Confidence score with colour-coded visual bar
- [x] Query history (sidebar + SQLite persistence)
- [x] Source citations with chunk excerpts and relevance scores
- [x] Intent classification displayed per response
- [x] 7-theme UI (Dark Purple, Midnight, Emerald, Sunset, Rose, Ocean, Light)
