#!/bin/bash
# Start both backend and frontend

echo "Starting AI Document Assistant..."

# Backend
echo "[1/2] Starting FastAPI backend on port 8000..."
cd backend
source venv/bin/activate
uvicorn main:app --reload --port 8000 &
BACKEND_PID=$!
cd ..

sleep 2

# Frontend
echo "[2/2] Starting React frontend on port 5173..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "✓ Backend running at http://localhost:8000"
echo "✓ Frontend running at http://localhost:5173"
echo "✓ API docs at http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop both servers."

trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT
wait
