## Get start locally

### Create virtual environment

```
python -m venv .venv
```

or

```
uv venv
```

### Activate venv

```
.\.venv\Scripts\Activate.ps1
```

or

```
.\.venv\Scripts\Activate
```

### Install dependencies

```
pip install -r requirements.txt

python.exe -m pip install --upgrade pip
```

or

```
uv sync
```

### Run a script

```
uv run main.py
```

## Jupyter Nodebook

### How to start jupyter notebook

```
jupyter --version

jupyter notebook

```

```
uvicorn src.mani:app --reload --host 0.0.0.0 --port 8000

uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```
