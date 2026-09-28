"""Выгрузка спецификации OpenAPI в файл.

ТЗ раздел 3.2: «при наличии серверной части программный интерфейс должен
быть описан в спецификации OpenAPI». Спецификация генерируется из кода —
руками её не правим.

    python scripts/export_openapi.py            # backend/openapi.json
    python scripts/export_openapi.py путь.json
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app  # noqa: E402

DEFAULT_PATH = Path(__file__).resolve().parent.parent / "openapi.json"


def main() -> None:
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PATH
    target.write_text(
        json.dumps(app.openapi(), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"OpenAPI записан в {target}")


if __name__ == "__main__":
    main()
