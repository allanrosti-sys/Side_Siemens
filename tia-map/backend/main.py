from __future__ import annotations

from fastapi import FastAPI

from api.routes import graph_router, health_router

app = FastAPI(
    title="TIA Map Backend",
    version="0.1.0",
    description="API para analise de blocos TIA exportados em XML.",
)

app.include_router(health_router)
app.include_router(graph_router)

