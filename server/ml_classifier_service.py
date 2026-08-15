from pathlib import Path
from typing import Any

import joblib


BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "ml_models"


INTENT_MODEL_PATH = MODEL_DIR / "intent_model_v2.joblib"
EVENT_MODEL_PATH = MODEL_DIR / "event_type_model_v3.joblib"


class AstraModel:
    def __init__(
        self,
        model_path: Path,
        model_name: str,
        version: str,
    ):
        if not model_path.exists():
            raise FileNotFoundError(
                f"Model not found: {model_path}"
            )

        self.model = joblib.load(model_path)
        self.model_name = model_name
        self.version = version

        if not hasattr(self.model, "predict"):
            raise TypeError(
                f"{model_name} does not support predict()."
            )

        if not hasattr(self.model, "predict_proba"):
            raise TypeError(
                f"{model_name} does not support predict_proba()."
            )

    def classify(self, text: str) -> dict[str, Any]:
        cleaned = str(text).strip()

        if not cleaned:
            raise ValueError(
                "text must not be empty"
            )

        prediction = self.model.predict(
            [cleaned]
        )[0]

        probabilities = self.model.predict_proba(
            [cleaned]
        )[0]

        classes = list(
            self.model.named_steps[
                "clf"
            ].classes_
        )

        best_index = int(
            probabilities.argmax()
        )

        confidence = float(
            probabilities[best_index]
        )

        top_indices = probabilities.argsort()[::-1][:3]

        top_predictions = [
            {
                "label": str(classes[index]),
                "confidence": float(
                    probabilities[index]
                ),
            }
            for index in top_indices
        ]

        return {
            "model": self.model_name,
            "version": self.version,
            "prediction": str(prediction),
            "confidence": confidence,
            "top_predictions": top_predictions,
        }


intent_model = AstraModel(
    model_path=INTENT_MODEL_PATH,
    model_name="astra_intent_classifier",
    version="v2",
)

event_model = AstraModel(
    model_path=EVENT_MODEL_PATH,
    model_name="astra_event_classifier",
    version="v3",
)
