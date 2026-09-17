from fastapi import FastAPI

app = FastAPI(title="LCT Hackathon Backend")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
