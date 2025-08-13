# Thesis System App

This repository contains the **frontend** (mobile app) for the Thesis System. It is built with Flutter (Dart) and connects to the backend API for managing thesis workflows.

- **Backend repository:** [IndoTexh/thesis-system](https://github.com/IndoTexh/thesis-system)

## Overview

The Thesis System App enables students, advisors, and administrators to interact with the thesis management system directly from their mobile devices.

- **Frontend:** Dart (Flutter)
- **Backend:** PHP (Laravel) — see the [thesis-system](https://github.com/IndoTexh/thesis-system) repo

## Features

- [x] User login and registration
- [ ] Submit and track thesis progress
- [ ] Advisor-student messaging
- [ ] Notifications and status updates
- [ ] Admin views for user and thesis management

## Setup

### Requirements

- Flutter SDK (>=3.x)
- Dart
- Android Studio or Xcode (for building mobile apps)

### Installation

```bash
git clone https://github.com/Ithnoobs/thesis_sys_app.git
cd thesis_sys_app
flutter pub get
flutter run
```

> **Note:** Update the API URL in your app configuration to point to your running [thesis-system backend](https://github.com/IndoTexh/thesis-system).

## API

This app interacts with the REST API provided by the [IndoTexh/thesis-system backend](https://github.com/IndoTexh/thesis-system). Refer to the backend repository for API documentation.

## License

MIT

---
**See the [backend](https://github.com/IndoTexh/thesis-system) for API and server-side logic.**