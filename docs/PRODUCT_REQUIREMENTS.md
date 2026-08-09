# ASTRA — Product Requirements Document

**Document Version:** 1.0  
**Product Stage:** V1 Architecture  
**Platform:** Android  
**Primary Client:** Flutter  
**Native Integration:** Kotlin where system-level Android integration is required  

---

# 1. Product Vision

ASTRA is an AI-assisted personal planning, scheduling, reminder, and focus management application.

ASTRA acts as a personal life operations assistant.

The application converts unstructured information such as forwarded messages, notices, announcements, deadlines, exam schedules, meeting information, and application opportunities into structured and actionable tasks.

ASTRA must help the user answer four questions:

1. What do I need to do?
2. When do I need to do it?
3. What should I focus on now?
4. What important event or deadline am I forgetting?

ASTRA is not a generic to-do application.

The primary product goal is to reduce the mental effort required to remember, organize, schedule, and follow up on important activities.

---

# 2. Core Product Principles

## 2.1 Database Is the Source of Truth

AI must never be treated as the source of truth.

Structured application data must be stored in deterministic database models.

Critical fields such as:

- Task status
- Deadline
- Reminder time
- Completion state
- Event date
- Study duration

must use typed database fields.

AI-generated text or metadata must not replace structured application data.

---

## 2.2 AI Proposes, Application Validates

AI may:

- Understand messages
- Extract task information
- Classify intent
- Suggest task titles
- Identify date expressions
- Suggest priorities
- Generate planning recommendations
- Explain schedules

AI must not directly:

- Insert trusted records into the database
- Mark tasks as completed
- Delete tasks
- Change critical deadlines silently
- Create final calendar facts
- Decide religious calendar dates
- Modify the user's entire schedule without confirmation

The required flow is:

Raw Input
→ AI Extraction
→ Structured Proposal
→ Validation
→ User Confirmation when required
→ Database Write

---

## 2.3 Deterministic Systems for Deterministic Work

The following systems must primarily use application logic rather than AI:

- Reminder triggering
- Task status transitions
- Deadline calculations
- Notification scheduling
- Study duration calculations
- Duplicate detection
- Calendar event storage
- Completion tracking
- Recurring ritual rules

AI may assist these systems but must not control their core execution.

---

## 2.4 Offline-First Core Experience

ASTRA must remain useful without a constant internet connection.

The following features must work locally where technically possible:

- View tasks
- View today's schedule
- Create manual tasks
- Complete tasks
- Start focus timer
- Stop focus timer
- View locally cached calendar information
- Trigger previously scheduled local reminders

AI processing and cloud synchronization may require internet connectivity.

Local changes must be synchronized when connectivity returns.

---

## 2.5 User Control

ASTRA is an assistant.

ASTRA is not an autonomous authority.

Critical schedule changes must be visible to the user.

The user must be able to:

- Confirm extracted tasks
- Edit extracted information
- Reject AI proposals
- Reschedule tasks
- Complete tasks
- Cancel tasks
- Modify reminder preferences

---

# 3. Target User

ASTRA V1 is initially designed as a single-user personal productivity system.

The primary user manages:

- College activities
- Exams
- Placement preparation
- Job and internship applications
- Meetings
- Technical learning
- Study schedules
- Personal tasks
- Important deadlines
- Religious or personal calendar routines

The V1 architecture should not prevent future multi-user support.

---

# 4. Core Product Modules

ASTRA V1 consists of the following primary modules:

1. Inbox
2. AI Extraction Engine
3. Tasks
4. Planner
5. Reminder Engine
6. Focus Tracker
7. Calendar
8. Panchang and Personal Ritual System
9. Personal Planning Intelligence
10. Settings and Preferences

---

# 5. Inbox Module

## 5.1 Purpose

The Inbox receives unstructured information that may contain actionable tasks, deadlines, events, or reminders.

---

## 5.2 Supported V1 Input Sources

V1 must support:

- Android shared text
- Manually pasted text
- Manually typed text

Examples of source applications may include:

- WhatsApp
- Telegram
- Gmail
- Browser
- Notes applications

ASTRA must not depend on direct access to private messages from third-party applications.

---

## 5.3 Android Share Flow

The intended flow is:

Third-Party Application
→ Android Share Action
→ ASTRA
→ Inbox Processing

Example:

User receives:

"Amazon SDE Internship applications close on 12 July."

The user shares the message to ASTRA.

ASTRA stores the original input as an inbox item.

ASTRA then processes the message.

---

## 5.4 Raw Message Preservation

The original shared text must be preserved.

ASTRA must not overwrite the raw source message with AI-generated content.

Each inbox item should maintain:

- Raw text
- Source type
- Received timestamp
- Processing state
- Extraction result reference
- User confirmation state

---

## 5.5 Processing States

An inbox item may have the following states:

- RECEIVED
- PROCESSING
- NEEDS_REVIEW
- PROCESSED
- FAILED
- IGNORED

---

# 6. AI Extraction Module

## 6.1 Purpose

The AI Extraction Module converts unstructured text into a structured proposal.

Example input:

"Guys CRT exam is tomorrow at 2 PM. Everyone must attend."

Possible structured proposal:

- Intent: EXAM
- Title: CRT Exam
- Date expression: tomorrow
- Time: 14:00
- Priority: HIGH
- Attendance required: true

---

## 6.2 Supported Intent Categories

V1 should support:

- EXAM
- APPLICATION
- MEETING
- ASSIGNMENT
- DEADLINE
- STUDY
- COLLEGE_EVENT
- PLACEMENT
- INTERVIEW
- PERSONAL
- INFORMATION
- UNKNOWN

The system must support future category expansion.

---

## 6.3 AI Confidence

Every AI extraction must contain a confidence score where supported by the extraction contract.

Low-confidence extractions must require user review.

ASTRA must never pretend uncertain information is confirmed.

Examples:

"Exam may be next Sunday."

ASTRA should identify uncertainty.

The application must present:

"Date needs confirmation."

---

## 6.4 Multiple Tasks in One Message

ASTRA must support multiple actionable items in one input.

Example:

"Register for the exam by 14 June. Hall tickets will be released on 18 June and the exam is on 23 June at 10 AM."

ASTRA should propose separate structured items:

1. Exam registration deadline
2. Hall ticket availability event
3. Exam event

Each proposal must be independently editable and confirmable.

---

## 6.5 Temporal Resolution

AI may identify temporal expressions such as:

- Tomorrow
- Next Sunday
- Tonight
- End of this week
- 12 July
- Monday morning

Final temporal resolution must be handled by a deterministic Temporal Resolver.

The resolver must consider:

- Current date
- User timezone
- Source message timestamp
- Explicit year
- Date ambiguity
- Time ambiguity

Default V1 timezone:

Asia/Kolkata

The timezone must remain configurable.

---

# 7. Task Management Module

## 7.1 Task Types

V1 task types include:

- APPLICATION
- EXAM_PREPARATION
- ASSIGNMENT
- STUDY
- MEETING_PREPARATION
- PLACEMENT
- PERSONAL
- GENERAL

---

## 7.2 Task Status

A task must use one of the following states:

- INBOX
- PLANNED
- IN_PROGRESS
- COMPLETED
- MISSED
- CANCELLED

Status transitions must be controlled by application logic.

---

## 7.3 Task Fields

A task may contain:

- Title
- Description
- Task type
- Priority
- Status
- Start time
- Due time
- Estimated duration
- Source inbox item
- Completion timestamp
- Creation timestamp
- Last modification timestamp

---

## 7.4 Task Completion

The user must be able to mark a task as completed.

When a task is completed:

1. Task status becomes COMPLETED.
2. Completion timestamp is recorded.
3. Pending reminders associated with the task are cancelled where appropriate.
4. The action is persisted locally.
5. The change is synchronized to the cloud when possible.

AI must not infer task completion without explicit user action or a trusted deterministic event.

---

# 8. Reminder Engine

## 8.1 Purpose

The Reminder Engine ensures important tasks and deadlines are not forgotten.

The engine must use deterministic scheduling logic.

---

## 8.2 Reminder Rules

Reminder strategies may depend on task type and priority.

Example application deadline strategy:

- 7 days before
- 3 days before
- 1 day before
- 6 hours before

Example exam strategy:

- 7 days before
- 3 days before
- Previous evening
- Exam morning

These strategies must be configurable.

---

## 8.3 Reminder Actions

Notifications may provide actions such as:

- COMPLETE
- REMIND LATER
- OPEN TASK

Future versions may support additional contextual actions.

---

## 8.4 Reminder Reliability

ASTRA must design reminders for Android 13 and newer.

The reminder architecture must account for:

- Notification permission
- Application process termination
- Device restart
- Exact alarm restrictions
- Battery optimization
- Rescheduling pending reminders
- Duplicate notification prevention

The application must not claim a reminder is reliably scheduled if scheduling failed.

Scheduling state must be tracked.

---

# 9. Planner Module

## 9.1 Purpose

The Planner organizes tasks into a practical daily schedule.

---

## 9.2 Planner Inputs

The planner may consider:

- Existing calendar events
- Task deadlines
- Task priorities
- Estimated task durations
- User-defined working hours
- Study goals
- Existing planned blocks
- Personal routines
- Panchang-related personal rules
- Historical focus statistics

---

## 9.3 Planner Output

The planner should create schedule proposals.

Example:

07:00 - 08:30
GATE Operating Systems

10:00 - 16:00
College

17:00 - 17:30
Amazon Application

18:00 - 19:00
DSA Practice

The initial V1 planner must require confirmation before applying major AI-generated schedule changes.

---

## 9.4 Missed Schedule Blocks

If a planned task is missed, ASTRA may suggest:

- Reschedule today
- Move to tomorrow
- Skip occurrence
- Manually choose time

ASTRA must not repeatedly reschedule tasks indefinitely without user awareness.

---

# 10. Focus Tracker

## 10.1 Purpose

The Focus Tracker provides YPT-style study and focused-work tracking.

---

## 10.2 Focus Session

The user must be able to:

1. Select a category.
2. Select a subject or project.
3. Select an optional topic.
4. Start the timer.
5. Pause where supported.
6. Stop the timer.
7. Save the completed session.

---

## 10.3 Example Hierarchy

GATE
→ Operating Systems
→ Deadlocks

DSA
→ Arrays
→ Sliding Window

AI/ML
→ Embeddings

Project
→ ASTRA

---

## 10.4 Focus Statistics

ASTRA should calculate:

- Today's total focus time
- Weekly focus time
- Time per category
- Time per subject
- Study streak
- Daily consistency

Statistics must be calculated from recorded session data.

AI must not fabricate productivity statistics.

---

# 11. Calendar Module

## 11.1 Event Types

Calendar events may include:

- EXAM
- MEETING
- INTERVIEW
- COLLEGE
- PLACEMENT
- PERSONAL
- RELIGIOUS

---

## 11.2 Calendar Views

V1 should support:

- Today
- Upcoming
- Calendar overview

Detailed month and week views may be introduced based on implementation priority.

---

# 12. Panchang and Personal Ritual Module

## 12.1 Purpose

ASTRA should help the user prepare for personally important Telugu calendar and Panchang events.

Examples include:

- Ekadashi
- Purnima / Pournami
- Amavasya
- Other configured important days

---

## 12.2 Calendar Fact Safety

AI must never independently decide whether a specific date is Ekadashi, Purnima, Amavasya, or another Panchang event.

Calendar facts must originate from:

- A verified calendar calculation engine
- A trusted structured data provider
- User-confirmed calendar data

AI may explain confirmed calendar facts.

---

## 12.3 Personal Ritual Rules

The user may define a reusable rule.

Example:

Event:
EKADASHI

Reminder:
1 day before

Personal instructions:
- Prepare required items
- Adjust tomorrow's schedule
- Follow saved personal routine

The rule should be created once and reused for future matching events.

---

## 12.4 Panchang Reminder Flow

Confirmed Panchang Event
→ Match Personal Ritual Rules
→ Generate Required Tasks or Reminders
→ Schedule Notifications

This process must use deterministic rule matching.

---

# 13. Personal Planning Intelligence

ASTRA may gradually use historical application data to improve planning suggestions.

Examples of derived statistics:

- Average focus session duration
- Frequently missed schedule times
- Most productive study periods
- Average task completion delay
- Subject study consistency

These statistics must be calculated deterministically.

AI may use these calculated statistics to produce planning recommendations.

Example:

"You usually complete focused study sessions more consistently between 7 AM and 9 AM. I suggest scheduling Operating Systems during that period."

ASTRA must not claim to have learned a behavior unless sufficient recorded data exists.

---

# 14. Home Experience

The home screen should answer:

- What should I do now?
- What is next?
- What is urgent?
- How much focus work have I completed today?

Suggested structure:

Greeting

Today's summary

Current or next schedule block

Urgent deadlines

Upcoming important events

Today's focus progress

AI planning suggestion when relevant

The home screen must avoid excessive dashboards and unnecessary graphs.

---

# 15. Design Requirements

ASTRA should feel comparable in quality to modern productivity applications.

Design inspiration may be taken from:

- Google Calendar
- Google Tasks
- Microsoft To Do
- Linear

ASTRA must not directly copy proprietary application designs.

The visual language should be:

- Calm
- Modern
- Minimal
- Focused
- Professional
- Adaptive

The UI must avoid:

- Excessive gradients
- Excessive glassmorphism
- Neon AI styling
- Unnecessary animations
- Crowded dashboards

ASTRA should use Material 3 principles.

Primary target:

Android 13 and newer.

The UI architecture should remain adaptive for different screen sizes.

---

# 16. Data Synchronization

ASTRA uses:

Local Database
→ Drift / SQLite

Cloud Database
→ Supabase PostgreSQL

Local storage supports offline-first usage.

Cloud storage supports:

- Backup
- Synchronization
- Future multi-device support

Synchronization logic must account for:

- Offline writes
- Retry
- Duplicate prevention
- Conflict handling
- Deleted records
- Updated records

The exact synchronization strategy must be defined in SYSTEM_ARCHITECTURE.md.

---

# 17. Security Requirements

ASTRA must:

- Never expose Gemini API secrets in the production mobile application.
- Never expose privileged Supabase credentials in the client.
- Use authenticated backend requests.
- Use Supabase Row Level Security.
- Validate AI output before persistence.
- Validate database writes.
- Protect user-owned records by user ID.
- Avoid logging sensitive raw message content unnecessarily.
- Use secure transport for network communication.

Detailed security rules are defined in SECURITY.md.

---

# 18. V1 Non-Goals

ASTRA V1 will not:

- Automatically scrape private WhatsApp chats.
- Read all WhatsApp unread messages.
- Train a custom large language model.
- Use Redis as the primary database.
- Use MongoDB as the primary database.
- Allow AI to directly control the database.
- Autonomously modify the entire user schedule.
- Use AI to calculate Panchang dates.
- Support iOS as the primary launch platform.
- Become a social productivity network.
- Include payments or subscriptions.
- Include unnecessary generative AI chat features.

---

# 19. V1 Success Criteria

ASTRA V1 is successful when the user can:

1. Share text from another Android application to ASTRA.
2. Preserve the original message.
3. Extract one or more actionable items using AI.
4. Review and confirm extracted information.
5. Store confirmed tasks in a structured database.
6. Receive reliable task reminders.
7. Complete tasks directly from the application.
8. View today's plan.
9. Track focused study sessions.
10. View focus statistics.
11. Receive reminders for configured personal calendar routines.
12. Use core task and focus features offline.
13. Synchronize supported data with the cloud.

---

# 20. Product Rule

When architecture, AI output, and user data disagree:

User-confirmed structured data is authoritative.

The database stores application truth.

Deterministic business rules control critical execution.

AI assists understanding and planning.

ASTRA must remain predictable, auditable, and user-controlled.