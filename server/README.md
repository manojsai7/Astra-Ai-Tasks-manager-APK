# ASTRA AI gateway

Run this service behind HTTPS and keep `GEMINI_API_KEY` only in its server
environment. The Flutter build receives just the public URL:

```powershell
flutter run --dart-define=ASTRA_API_BASE_URL=https://your-api.example.com
```

For development, copy `.env.example` to a private environment file, install
`requirements.txt`, then run:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8000
```

`GEMINI_MODEL=gemini-2.5-flash` is the default. Pin a model deliberately,
restrict the AI Studio key on the server, and add rate limiting and
authenticated requests before a public launch.

## Render deployment

The repository includes `render.yaml`. Create a Render Blueprint from the
repository, then enter `GEMINI_API_KEY` as a secret environment variable in
the Render dashboard. Use the generated HTTPS URL as `ASTRA_API_BASE_URL`.
Free Render services sleep after 15 idle minutes; the first request can take
about a minute to wake. For personal use, tolerate that first request; for a
public release, choose an always-on paid instance instead of relying on
third-party keep-alive pings.
