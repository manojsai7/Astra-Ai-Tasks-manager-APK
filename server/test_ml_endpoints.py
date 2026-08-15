import json

from fastapi.testclient import TestClient

from main import app


client = TestClient(app)


tests = [
    (
        "/ml/classify-intent",
        "remind me to drink water in 2 mins",
        "CREATE_REMINDER",
    ),
    (
        "/ml/classify-intent",
        "show me my tasks",
        "LIST_TASKS",
    ),
    (
        "/ml/classify-intent",
        "sync my emails",
        "SYNC_EMAIL",
    ),
    (
        "/ml/classify-event",
        "bruh i have exam today at 6pm",
        "EXAM",
    ),
    (
        "/ml/classify-event",
        "Microsoft interview Monday at 11am",
        "INTERVIEW",
    ),
    (
        "/ml/classify-event",
        "fill the NPTEL form before 4pm",
        "FORM",
    ),
]


for endpoint, text, expected in tests:
    response = client.post(
        endpoint,
        json={"text": text},
    )

    print("\n" + "=" * 70)
    print("ENDPOINT:", endpoint)
    print("TEXT:", text)
    print("STATUS:", response.status_code)

    payload = response.json()

    print(
        json.dumps(
            payload,
            indent=2,
        )
    )

    assert response.status_code == 200

    assert (
        payload["prediction"]
        == expected
    )

print(
    "\n[SUCCESS] ALL ML ENDPOINT TESTS PASSED"
)
