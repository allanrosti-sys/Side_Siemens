from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routes import graph_router, health_router

app = FastAPI(
    title="TIA Map Backend",
    version="0.1.0",
    description="API para analise de blocos TIA exportados em XML.",
)

# Permite frontend local (Vite) consumir a API durante desenvolvimento.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(graph_router)
