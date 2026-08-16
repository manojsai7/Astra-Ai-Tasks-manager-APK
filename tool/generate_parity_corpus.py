import json
from pathlib import Path
import joblib
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
SERVER_MODELS_DIR = BASE_DIR / "server" / "ml_models"

# Representative 120+ utterances covering Set A intents and Set B event categories
TEST_UTTERANCES = [
    # Set A: Reminders & Tasks
    "remind me to drink water in 2 mins",
    "remind me to call Mom tomorrow at 6pm",
    "set a reminder for my assignment deadline on Friday",
    "reminder to take medicine in 1 hour",
    "create a task to finish the physics report",
    "add task submit internship application by 5pm",
    "water plants every morning at 7am",
    "standup every weekday at 10am",
    "walk the dog daily at 8pm",
    "team sync weekly on Monday at 3pm",
    "pay electric bill monthly on 1st",

    # Set A: Calendar & Meetings
    "schedule a meeting with John tomorrow at 2pm",
    "put the design review on my calendar for Tuesday at 4pm",
    "add it to my calendar next Wednesday at 11am",
    "schedule a call with Sarah on Friday at 10am",
    "create calendar event project kickoff Thursday 9am",

    # Set A: Updates & Cancellations & Completions
    "move my exam to tomorrow at 7pm",
    "reschedule my Microsoft interview to 2pm",
    "postpone the standup to 11am",
    "change my assignment deadline to Friday",
    "rename my exam to Physics Final Exam",
    "cancel my reminder for tomorrow",
    "delete task buy groceries",
    "mark my physics homework as done",
    "i have finished my chemistry assignment",
    "done with my morning workout",

    # Set A: Listing & Queries
    "show my tasks",
    "list my todos",
    "what are my pending tasks for today",
    "view all my tasks",
    "what is on my calendar today",
    "show my upcoming meetings",
    "when is my next interview",

    # Set A: Email & Sync
    "sync my emails",
    "refresh inbox",
    "summarize my latest email from Google",
    "search email about offer letter",
    "check new mails from college",

    # Set A: Panchang
    "what is today's tithi",
    "when is the next ekadashi",
    "check rahu kalam for tomorrow",
    "is today purnima or amavasya",

    # Set A: General Chat
    "hello there",
    "good morning",
    "how are you doing",
    "what can you do for me",
    "tell me a joke",

    # Set B: Event Types (Exam, Interview, Assignment, Workshop, Fee, Form, Application, etc.)
    "Microsoft interview Monday at 11am",
    "Google software engineer technical interview round 2",
    "Amazon bar raiser interview on Friday at 3pm",
    "physics mid semester examination hall ticket",
    "maths final exam paper submission on 25th May",
    "checkpoint test for algorithms course",
    "machine learning assignment 3 deadline is midnight",
    "chemistry lab report homework due Tuesday",
    "ai and robotics workshop registration opens tomorrow",
    "cyber security training session by Cisco next week",
    "pay college semester tuition fee before deadline",
    "exam fee payment portal closes tonight",
    "fill the student feedback form for semester 4",
    "submit course feedback survey",
    "scholarship application for national merit scheme",
    "internship application for software developer role",
    "collect hall ticket from administrative block",
    "download admit card for entrance exam",
    "data structures lecture Monday 9am",
    "physics class rescheduled to classroom 302",
    "annual alumni meet 2026",
    "cultural festival inauguration evening",
    "weekly badminton game with friends",
    "buy milk and bread on the way home",
    "clean the bedroom desk",
    "car service appointment Saturday morning",
    "dentist checkup next Tuesday at 5pm",
    "flight to Bangalore departure at 6:30am",
    "hotel reservation confirmation details",
    "read 20 pages of clean code",
    "meditation for 15 minutes before sleep",
    "gym leg workout at 6pm",
    "morning yoga session at sunrise",
    "renew passport document application",
    "submit tax return documents before July 31st",
    "review pull request for authentication service",
    "deploy new release to staging environment",
    "quarterly business review presentation prep",
    "client product demo on Thursday at 2pm",
    "prepare slides for conference speech",
    "attend blockchain webinar on Zoom",
    "parent teacher meeting Friday 10am",
    "blood donation camp registration",
    "order new laptop charger from Amazon",
    "pay electricity bill before due date",
    "renew car insurance policy online",
    "return library books before fine accumulates",
    "submit expense reimbursement form",
    "update resume with latest project details",
    "solve 3 leetcode problems on graphs",
    "practice mock interview on system design",
    "biology lab experiment record submission",
    "english essay drafting on artificial intelligence",
    "attend virtual job fair on Saturday",
    "orientation ceremony for new students",
    "hackathon team registration deadline",
    "hostel room fee payment receipt download",
    "submit project synopsis to guide",
    "final semester project viva presentation",
    "graduate degree certificate collection",
    "internship joining letter verification",
    "onboarding session for new joiners",
    "weekly team retrospective meeting",
    "one on one sync with engineering manager",
    "all hands meeting on company roadmap",
    "monthly financial budget review",
    "grocery shopping list for the weekend",
    "plan birthday party celebration dinner",
    "call insurance agent regarding claim",
    "schedule plumbing repair for kitchen sink",
    "water indoor plants every 3 days",
    "evening run 5km in the park",
    "listen to tech podcast episode on LLMs",
    "study compiler design chapter 4",
    "watch tutorial on Flutter state management",
]


def generate_parity_dataset():
    intent_model_path = SERVER_MODELS_DIR / "intent_model_v2.joblib"
    event_model_path = SERVER_MODELS_DIR / "event_type_model_v3.joblib"

    intent_pipeline = joblib.load(intent_model_path)
    event_pipeline = joblib.load(event_model_path)

    parity_cases = []

    for text in TEST_UTTERANCES:
        # Set A predictions
        intent_pred = str(intent_pipeline.predict([text])[0])
        intent_probs = intent_pipeline.predict_proba([text])[0]
        intent_classes = list(intent_pipeline.named_steps["clf"].classes_)
        intent_top_indices = intent_probs.argsort()[::-1][:3]
        intent_top = [
            {"label": str(intent_classes[i]), "confidence": float(intent_probs[i])}
            for i in intent_top_indices
        ]

        # Set B predictions
        event_pred = str(event_pipeline.predict([text])[0])
        event_probs = event_pipeline.predict_proba([text])[0]
        event_classes = list(event_pipeline.named_steps["clf"].classes_)
        event_top_indices = event_probs.argsort()[::-1][:3]
        event_top = [
            {"label": str(event_classes[i]), "confidence": float(event_probs[i])}
            for i in event_top_indices
        ]

        parity_cases.append({
            "text": text,
            "set_a": {
                "prediction": intent_pred,
                "confidence": float(intent_probs[intent_top_indices[0]]),
                "top_predictions": intent_top,
            },
            "set_b": {
                "prediction": event_pred,
                "confidence": float(event_probs[event_top_indices[0]]),
                "top_predictions": event_top,
            },
        })

    out_path = BASE_DIR / "test" / "fixtures" / "ml_parity_corpus.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(parity_cases, f, indent=2)

    print(f"Generated {len(parity_cases)} parity test cases -> {out_path}")


if __name__ == "__main__":
    generate_parity_dataset()
