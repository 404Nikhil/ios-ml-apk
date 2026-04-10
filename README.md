# Abrats - Smart eCommerce iOS Application

This is the Smart eCommerce frontend for the AITHON 2026 hackathon. It features an intelligent "Smart Cart" powered by a FastAPI ML backend, providing dynamic recommendations and a premium shopping experience.

## ✨ Features
- **Intelligent Recommendations**: "Frequently bought together" and "Similar items" sections powered by ML.
- **Seamless Refresh**: Debounced background updates ensure the UI never flashes while adding items.
- **Dynamic Trending Items**: Real catalog products displayed in the empty cart state.
- **Modern UI/UX**: Premium design with high-fidelity components, skeletons, and spring animations.

## 🚀 Getting Started
### Prerequisites
- **macOS** with **Xcode 16.0+**
- **Git**
- **Python 3.9+** (for the ML backend)


### 1. Clone the Project
```bash
git clone https://github.com/wigglevig/AI-THON.git
cd AI-THON
```


### 2. Setup the Backend
The app relies on the `intcart_backend` to serve products and recommendations.
```bash
cd intcart_backend
# Install dependencies
pip install -r requirements.txt
# Run the FastAPI server
python3 -m uvicorn app:app --host 0.0.0.0 --port 8000
```
*Port 8000 is required for the iOS app to fetch products.*

### 3. Open in Xcode
1. Navigate to the project root in Finder.
2. Locate the `.xcodeproj` file.
3. Open it with Xcode:
   ```bash
   open ../WSHackathonApp.xcodeproj
   ```

### 4. Build and Run
1. Select a simulator (e.g., **iPhone 17 Pro**).
2. Press **Cmd + R** to build and run.
3. Ensure the backend is running to see products and images.

## 🛠 Tech Stack
- **Frontend**: SwiftUI, Combine
- **Backend**: FastAPI (Python)
- **Image Serving**: FastAPI StaticFiles (serving label-matched product images)

---
Developed for AI-THON 2026.
