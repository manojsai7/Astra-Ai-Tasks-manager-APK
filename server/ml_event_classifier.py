from pathlib import Path
from typing import Any

import joblib


BASE_DIR = Path(__file__).resolve().parent

MODEL_PATH = (
    BASE_DIR
    / "ml_models"
    / "event_type_model_v3.joblib"
)


class B1EventClassifier:
    def __init__(self, model_path: Path = MODEL_PATH):
        if not model_path.exists():
            raise FileNotFoundError(
                f"B1 model not found: {model_path}"
            )

        self.model = joblib.load(model_path)

        if not hasattr(self.model, "predict"):
            raise TypeError(
                "Loaded B1 artifact does not expose predict()."
            )

        if not hasattr(self.model, "predict_proba"):
            raise TypeError(
                "Loaded B1 artifact does not expose predict_proba()."
            )

        # LogisticRegression classes
        self.classes = [
            str(value)
            for value in self.model.named_steps["clf"].classes_
        ]

    def classify(self, text: str) -> dict[str, Any]:
        text = str(text).strip()

        if not text:
            raise ValueError("text must not be empty")

        prediction = self.model.predict([text])[0]

        probabilities = self.model.predict_proba([text])[0]

        best_index = int(probabilities.argmax())

        confidence = float(
            probabilities[best_index]
        )

        top_indices = probabilities.argsort()[::-1][:3]

        top_predictions = [
            {
                "event_type": str(
                    self.classes[index]
                ),
                "confidence": float(
                    probabilities[index]
                ),
            }
            for index in top_indices
        ]

        return {
            "model": "astra_b1_event_type",
            "version": "v3",
            "event_type": str(prediction),
            "confidence": confidence,
            "top_predictions": top_predictions,
        }


classifier = B1EventClassifier()