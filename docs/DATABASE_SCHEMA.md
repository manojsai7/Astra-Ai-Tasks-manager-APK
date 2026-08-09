# ASTRA — Database Schema

ASTRA uses:

- Drift + SQLite for local runtime data
- Supabase PostgreSQL for cloud synchronization
- UUIDs for record IDs

## Core Tables

### profiles
- id
- name
- timezone
- wake_time
- sleep_time
- created_at
- updated_at

### inbox_items
- id
- user_id
- raw_text
- source_type
- processing_status
- received_at
- created_at
- updated_at

### extraction_runs
- id
- inbox_item_id
- ai_provider
- extraction_status
- confidence
- raw_ai_output_json
- created_at

### tasks
- id
- user_id
- inbox_item_id
- title
- description
- task_type
- priority
- status
- start_at
- due_at
- estimated_minutes
- completed_at
- created_at
- updated_at
- deleted_at
- sync_status

### reminders
- id
- task_id
- remind_at
- reminder_type
- status
- notification_id
- triggered_at
- created_at
- updated_at

### calendar_events
- id
- user_id
- title
- event_type
- start_at
- end_at
- source
- created_at
- updated_at

### planned_blocks
- id
- user_id
- task_id
- title
- start_at
- end_at
- status
- created_at
- updated_at

### focus_categories
- id
- user_id
- name
- parent_id
- created_at

### focus_sessions
- id
- user_id
- category_id
- task_id
- started_at
- ended_at
- paused_seconds
- duration_seconds
- status
- created_at

### panchang_events
- id
- event_type
- event_date
- start_at
- end_at
- source
- created_at

### ritual_rules
- id
- user_id
- event_type
- title
- instructions
- remind_days_before
- reminder_time
- enabled
- created_at
- updated_at

## Database Rule

AI never directly writes trusted domain records.

AI Output
→ Validation
→ User Confirmation when required
→ Repository
→ Database

Critical data uses typed columns.

JSON is allowed only for flexible AI metadata and raw extraction output.