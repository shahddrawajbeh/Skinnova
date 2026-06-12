from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
import tempfile
from inference_sdk import InferenceHTTPClient
from ultralytics import YOLO

app = FastAPI()

# Allow the web app (and local dev servers) to call this API directly from the browser
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = YOLO("yolov8n-face.pt")
client = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key="DMZSf1rgWjIXgYwc28lj"
 )

@app.post("/check-image")
async def check_image(image: UploadFile = File(...)):
    contents = await image.read()

    np_arr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if img is None:
        return {
            "isValid": False,
            "message": "Could not read image."
        }

    height, width, _ = img.shape

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    brightness = float(np.mean(gray))

    sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())

    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp:
        temp.write(contents)
        temp_path = temp.name

    results = model(temp_path)

    faces = results[0].boxes

    if len(faces) == 0:
        return {
            "isValid": False,
            "message": "No face detected."
        }

    if len(faces) > 1:
        return {
            "isValid": False,
            "message": "Multiple faces detected."
        }

    box = faces[0].xyxy[0].cpu().numpy()

    x1, y1, x2, y2 = box

    face_width = x2 - x1
    face_height = y2 - y1

    face_area = face_width * face_height
    image_area = width * height

    face_ratio = face_area / image_area

    if face_ratio < 0.12:
        return {
            "isValid": False,
            "message": "Move closer to the camera."
        }

    face_center_x = (x1 + x2) / 2
    face_center_y = (y1 + y2) / 2

    image_center_x = width / 2
    image_center_y = height / 2

    if abs(face_center_x - image_center_x) > width * 0.25:
        return {
            "isValid": False,
            "message": "Center your face."
        }

    if brightness < 70:
        return {
            "isValid": False,
            "message": "Lighting is too dark."
        }

    if brightness > 200:
        return {
            "isValid": False,
            "message": "Lighting is too bright."
        }

    if sharpness < 40:
        return {
            "isValid": False,
            "message": "Image is blurry."
        }

    return {
        "isValid": True,
        "message": "Image is ready for skin analysis.",
        "brightness": brightness,
        "sharpness": sharpness
    }
@app.post("/analyze-skin")
async def analyze_skin(image: UploadFile = File(...)):
    contents = await image.read()

    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp:
        temp.write(contents)
        temp_path = temp.name

    result1 = client.run_workflow(
        workspace_name="shahds-workspace-psddq",
        workflow_id="custom-workflow",
        images={"image": temp_path},
        use_cache=True
    )

    result2 = client.run_workflow(
        workspace_name="shahds-workspace-psddq",
        workflow_id="custom-workflow-2",
        images={"image": temp_path},
        use_cache=True
    )

    predictions1 = result1[0]["model_output"]["predictions"]
    predictions2 = result2[0]["model_output"]["predictions"]
    predictions = predictions1 + predictions2

    pretty_names = {
        "skin-pore": "Skin Pore",
        "enlarged_pores": "Enlarged Pores",
        "freckles": "Freckles",
        "whitehead": "Whitehead",
        "whiteheads": "Whiteheads",
        "blackhead": "Blackhead",
        "blackheads": "Blackheads",
        "acne": "Acne",
        "acne_scars": "Acne Scars",
        "wrinkle": "Wrinkle",
        "wrinkles": "Wrinkles",
        "Dark Circle": "Dark Circle",
        "dark circle": "Dark Circle",
    }

    counts = {}

    for p in predictions:
        raw_name = p["class"]
        display_name = pretty_names.get(raw_name, raw_name)
        counts[display_name] = counts.get(display_name, 0) + 1

    metrics = []

    for name, count in counts.items():
        related = [
            p for p in predictions
            if pretty_names.get(p["class"], p["class"]) == name
        ]

        avg_confidence = sum(p["confidence"] for p in related) / len(related)
        score = int(min(100, (count * 10) + (avg_confidence * 70)))

        if score >= 70:
            status = "Needs care"
        elif score >= 35:
            status = "Moderate"
        else:
            status = "Good"

        metrics.append({
            "name": name,
            "score": score,
            "status": status
        })

    if len(metrics) == 0:
        metrics = [
            {"name": "Clear Skin", "score": 90, "status": "Good"}
        ]

    main_concern = metrics[0]["name"]

    morning_routine, night_routine = build_routine_from_raw_metrics(metrics)

    return {
        "skinScore": max(45, 95 - len(predictions)),
        "potentialScore": 98,
        "improvementTime": "3 Months",
        "mainConcern": main_concern,
        "metrics": metrics,
        "morningRoutine": morning_routine,
        "nightRoutine": night_routine
    }


def build_routine_from_raw_metrics(metrics):
    names = [m["name"].lower() for m in metrics]

    morning = [
        {"step": 1, "name": "Gentle Cleanser", "why": "Cleans the skin without irritating it.", "ingredient": "Gentle Cleanser", "category": "cleanser"},
        {"step": 2, "name": "Light Moisturizer", "why": "Keeps the skin barrier hydrated.", "ingredient": "Ceramides", "category": "moisturizer"},
        {"step": 3, "name": "Sunscreen SPF 50", "why": "Protects the skin during the day.", "ingredient": "Sunscreen", "category": "sunscreen"},
    ]

    night = [
        {"step": 1, "name": "Gentle Cleanser", "why": "Removes sunscreen, oil, and dirt.", "ingredient": "Gentle Cleanser", "category": "cleanser"},
        {"step": 2, "name": "Barrier Repair Moisturizer", "why": "Supports skin recovery overnight.", "ingredient": "Ceramides", "category": "moisturizer"},
    ]

    if any(x in names for x in ["acne", "blackhead", "blackheads", "whitehead", "whiteheads"]):
        night.insert(1, {
            "step": 2,
            "name": "Salicylic Acid Treatment",
            "why": "Helps clogged pores, blackheads, whiteheads, and acne.",
            "ingredient": "Salicylic Acid",
            "category": "treatment"
        })

    if any(x in names for x in ["skin pore", "enlarged pores"]):
        morning.insert(1, {
            "step": 2,
            "name": "Niacinamide Serum",
            "why": "Helps reduce the look of pores and balance oil.",
            "ingredient": "Niacinamide",
            "category": "serum"
        })

    if any(x in names for x in ["freckles", "acne scars"]):
        morning.insert(1, {
            "step": 2,
            "name": "Vitamin C Serum",
            "why": "Helps brighten uneven tone and dark marks.",
            "ingredient": "Vitamin C",
            "category": "serum"
        })

    if any(x in names for x in ["wrinkle", "wrinkles", "dark circle"]):
        night.insert(1, {
            "step": 2,
            "name": "Retinol Treatment",
            "why": "Supports texture and fine lines. Start slowly.",
            "ingredient": "Retinol",
            "category": "treatment"
        })

    for i, step in enumerate(morning):
        step["step"] = i + 1

    for i, step in enumerate(night):
        step["step"] = i + 1

    return morning, night