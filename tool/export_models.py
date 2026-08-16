import json
from pathlib import Path
import joblib
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
SERVER_MODELS_DIR = BASE_DIR / "server" / "ml_models"
ASSETS_DIR = BASE_DIR / "assets" / "models"


def export_pipeline(model_path: Path, output_json_path: Path, model_name: str, version: str):
    if not model_path.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")

    pipeline = joblib.load(model_path)
    tfidf = pipeline.named_steps["tfidf"]
    clf = pipeline.named_steps["clf"]

    # 1. TF-IDF parameters
    vocabulary = {str(k): int(v) for k, v in tfidf.vocabulary_.items()}
    idf = [float(x) for x in tfidf.idf_]
    ngram_range = [int(x) for x in tfidf.ngram_range]

    # 2. Logistic Regression parameters
    classes = [str(c) for c in clf.classes_]
    # coef_ shape: (n_classes, n_features)
    coef = [[float(c) for c in row] for row in clf.coef_]
    # intercept_ shape: (n_classes,)
    intercept = [float(x) for x in clf.intercept_]

    model_data = {
        "model_name": model_name,
        "version": version,
        "vectorizer": {
            "lowercase": bool(tfidf.lowercase),
            "ngram_range": ngram_range,
            "sublinear_tf": bool(tfidf.sublinear_tf),
            "norm": str(tfidf.norm),
            "use_idf": bool(tfidf.use_idf),
            "smooth_idf": bool(tfidf.smooth_idf),
            "vocabulary": vocabulary,
            "idf": idf,
        },
        "classifier": {
            "classes": classes,
            "coef": coef,
            "intercept": intercept,
        },
    }

    output_json_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_json_path, "w", encoding="utf-8") as f:
        json.dump(model_data, f, separators=(",", ":"))

    size_kb = output_json_path.stat().st_size / 1024
    print(f"Exported {model_name} ({version}) -> {output_json_path} ({size_kb:.1f} KB)")


def main():
    intent_model_path = SERVER_MODELS_DIR / "intent_model_v2.joblib"
    event_model_path = SERVER_MODELS_DIR / "event_type_model_v3.joblib"

    out_intent_json = ASSETS_DIR / "intent_model_v2.json"
    out_event_json = ASSETS_DIR / "event_type_model_v3.json"

    export_pipeline(intent_model_path, out_intent_json, "astra_intent_classifier", "v2")
    export_pipeline(event_model_path, out_event_json, "astra_event_classifier", "v3")


if __name__ == "__main__":
    main()
