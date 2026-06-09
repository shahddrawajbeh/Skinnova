# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Skinova is a skincare app with three independently-running services:

| Service | Path | Stack |
|---|---|---|
| Mobile frontend | `frontend/skinnova/` | Flutter (Dart) |
| REST API backend | `backend/skinnova-backend/` | Node.js + Express + MongoDB |
| AI skin analysis | `ai/skinova-ai-server/` | Python + FastAPI |

---

## Commands

### Frontend (Flutter)

```bash
cd frontend/skinnova
flutter pub get          # install dependencies
flutter run              # run on connected device/emulator
flutter build apk        # build Android APK
flutter test             # run tests
flutter test test/widget_test.dart  # run a single test file
```

### Backend (Node.js)

```bash
cd backend/skinnova-backend
npm install
node server.js           # start server on port 5000
```

Requires a `.env` file with `MONGO_URI` and `HF_TOKEN`.

### AI Server (Python / FastAPI)

```bash
cd ai/skinova-ai-server
pip install -r requirements.txt   # if requirements file exists; otherwise install manually
uvicorn main:app --reload --port 8000
```

Dependencies: `fastapi`, `uvicorn`, `opencv-python`, `numpy`, `ultralytics`, `inference-sdk`.

---

## Architecture

### Flutter Frontend

- **Entry point**: `lib/main.dart` → `SplashScreen` → `MainNavigationScreen`
- **All API calls** go through the single `ApiService` class in `lib/api_service.dart`. The base URL is hardcoded as `http://192.168.1.9:5000` — update this IP when the backend host changes.
- **Screens** live flat in `lib/screens/`. There is also `lib/features/skin_ai/` with a sub-feature structure (models, screens, services, widgets).
- **State** is not managed by a dedicated package (no Provider/Riverpod/Bloc); screens call `ApiService` directly and use `setState`.
- User session is persisted via `shared_preferences` (key: `"userId"`, `"userRole"`).

**User roles**: `user`, `seller`, `admin` — each has a different home screen (`home_screen.dart`, `seller_home_screen.dart`, `admin_home_screen.dart`). Role is read from shared preferences and controls navigation routing.

**Onboarding flow**: After registration, users complete a multi-step questionnaire (gender, age, skin type, concerns, phototype, sensitivity, etc.) before reaching the main app.

### Node.js Backend

Entry point: `server.js` on port `5000`. Route modules in `routes/`, Mongoose models in `models/`.

Key route groups:

| Mount | File | Purpose |
|---|---|---|
| `/api/auth` | `routes/auth.js` | Register, login, OTP, profile, follow/unfollow, collections |
| `/api/products` | `routes/products.js` | Product CRUD, reviews, filtering by brand/concern |
| `/api/product-scan` | `routes/productScanRoutes.js` | OCR barcode/label scan via Tesseract.js → product match |
| `/api/skin-scan` | `routes/skinScanRoutes.js` | HuggingFace ViT model for skin condition detection |
| `/api/groups` + `/api/group-posts` | `routes/group.js`, `routes/group_posts.js` | Community groups and threaded posts |
| `/api/cart`, `/api/orders` | `routes/cart.js`, `routes/orders.js` | Shopping cart and order checkout |
| `/api/stores`, `/api/store-products` | `routes/stores.js`, `routes/storeProducts.js` | Seller storefronts and product listings |
| `/api/ads` | `routes/adRoutes.js` | Seller ad submissions (admin-approved) |
| `/api/ingredients`, `/api/medications` | ingredient/medication routes | Educational content for skincare ingredients and skin medications |

Static uploads served from `/uploads/` directory.

### Python AI Server

`main.py` exposes two FastAPI endpoints:

- **`POST /check-image`**: Validates a face photo before skin scan (uses YOLOv8 face detection to check: face presence, face count, face size ratio, centering, brightness, sharpness).
- **`POST /analyze-skin`**: Runs two Roboflow workflows to detect skin conditions (acne, blackheads, wrinkles, pores, freckles, etc.), aggregates predictions, scores each condition, and returns metrics + a personalized morning/night skincare routine.

The Flutter app calls the AI server's `/check-image` and `/analyze-skin` endpoints directly (see `lib/skin_image_quality_service.dart` and `lib/skin_analysis_service.dart`). The AI server URL is configured separately from the backend base URL.

### Data Flow for Skin Scan

1. Flutter captures image via camera (`skin_camera_screen.dart`)
2. Calls Python AI server `/check-image` to validate image quality
3. If valid, calls `/analyze-skin` to get skin metrics + routine
4. Results displayed in `skin_result_screen.dart`
5. Scan history optionally saved via backend `/api/skin-scan`

### Product Scan Flow

1. User photographs product label
2. Flutter sends image to backend `/api/product-scan`
3. Backend runs Tesseract.js OCR on the image, scores against all published products by brand/name keyword matching (threshold: score ≥ 40)
4. Returns matched product or 404
