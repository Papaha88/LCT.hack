from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="LCT Hackathon Backend")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


# Пример-заглушка: показывает паттерн для остальных эндпоинтов.
# Сначала описываем форму ответа (Pydantic-модель) и отдаём фейковые
# данные — этого достаточно, чтобы мобильный разработчик уже сегодня
# писал сетевой слой под реальную форму JSON, не дожидаясь, пока тут
# появится настоящая логика с базой данных. Дальше просто подменяем
# "return PetState(...)" на реальный запрос к БД — контракт не меняется.
class PetState(BaseModel):
    name: str
    stage: int
    balance: float
    goal: float


@app.get("/pet/{user_id}")
def get_pet_state(user_id: int) -> PetState:
    return PetState(name="Кекс", stage=1, balance=1200.0, goal=5000.0)
