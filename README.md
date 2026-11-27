# Netlify Health

Netlify Health is an offline-first personal wellness journal for Windows and Android.

## Included in v1.1.0

- Dashboard based only on user-entered records (no fake sensor readings).
- Activity and vital records: steps, heart rate, weight, blood pressure, SpO2 and exercise minutes.
- Sleep journal with duration and quality.
- Daily water tracking and editable hydration goal.
- Meal ideas based on saved food preferences and foods to avoid.
- Medication list, dose notes, dose completion tracking, and in-app notification checks while the app is open.
- Appointment list, mood journal, and general wellness education.
- Optional personal profile and emergency contact details.
- JSON export/import and local data deletion.

## Build

- Windows installer: GitHub Actions workflow `.github/workflows/build-windows.yml`.
- Android debug APK: GitHub Actions workflow `.github/workflows/build-android.yml`.

## Important current limitations

This version stores data in the app's local browser storage on the current device. It does not yet provide cloud accounts, encrypted cloud backup, multi-device sync, automatic Health Connect / smartwatch imports, scheduled background medication alarms, clinical EHR or telemedicine connections, or an AI medical assistant. Browser notifications are checked only while the app is running. These capabilities require additional backend services, native integrations, credentials, permissions, and security review.

Netlify Health is not a medical device and does not diagnose, treat, or monitor emergencies. Meal ideas are general wellness suggestions and are not a prescribed diet. Follow your clinician's instructions for medical conditions, medication, and prescribed diets.
