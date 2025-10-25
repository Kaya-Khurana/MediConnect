# MediConnect - Smart Doctor Appointment Booking App 🩺

MediConnect is a Flutter-based mobile application designed to streamline the process of booking doctor appointments. It provides a user-friendly interface for patients to find doctors, book appointments, manage their medical history, and receive e-prescriptions, while offering doctors and administrators tools to manage schedules and user accounts.


## ScreenShots
<img width="300" height="600" alt="Screenshot_2025-10-25-23-05-24-30_bed02b0cbfcf719fcf7d049b315cb6ac-portrait" src="https://github.com/user-attachments/assets/57321cff-168e-4105-8c49-33c8e362ccc2" />

<img width="1419" height="2796" alt="Screenshot_2025-10-25-22-53-35-15_bed02b0cbfcf719fcf7d049b315cb6ac-portrait" src="https://github.com/user-attachments/assets/a928a343-68f1-4668-97b0-82795a9dd653" />

<img width="1419" height="2796" alt="Screenshot_2025-10-25-22-53-51-54_bed02b0cbfcf719fcf7d049b315cb6ac-portrait" src="https://github.com/user-attachments/assets/5e408a83-ace2-4ce6-b473-a1aa36cc4a0b" />

<img width="1419" height="2796" alt="Screenshot_2025-10-25-22-53-55-45_bed02b0cbfcf719fcf7d049b315cb6ac-portrait" src="https://github.com/user-attachments/assets/0de346d3-ecf6-4716-bdfa-d1c64333c983" />

<img width="1419" height="2796" alt="Screenshot_2025-10-25-22-54-06-50_bed02b0cbfcf719fcf7d049b315cb6ac-portrait" src="https://github.com/user-attachments/assets/106104e2-77bf-43d3-a532-0f22b2934832" />

<img width="1419" height="2796" alt="Screenshot_2025-10-25-22-54-02-57_bed02b0cbfcf719fcf7d049b315cb6ac-portrait" src="https://github.com/user-attachments/assets/03f1b1e6-dec5-433f-a801-01f17339ac70" />

## ✨ Features

The application is divided into several key modules:

1.  **User Module (Patient):**
    * User registration and login.
    * Search and filter doctors by specialty, location, etc. (Partially Implemented)
    * View doctor profiles and availability.
    * Book appointments.
    * View booking history.
    * View prescriptions.
    * Book lab tests. (Partially Implemented)

2.  **Doctor Module:**
    * Doctor registration and login (with Admin approval).
    * Manage profile details (specialty, qualifications, fees, address).
    * View pending appointment requests.
    * Approve/Deny appointment requests.
    * View confirmed schedule.
    * Write and manage e-prescriptions for patients.

3.  **Admin Module:**
    * Admin login.
    * View all registered users (patients, doctors, labs).
    * View all registered professionals (doctors, labs).
    * Approve/Reject pending doctor and lab registrations.
    * Delete users/professionals (data only, Auth deletion requires backend).

4.  **Laboratory Module:**
    * Lab registration and login (with Admin approval).
    * Manage lab profile (name, address, services).
    * View pending lab test requests.
    * Confirm/Cancel lab test requests.

5.  **Appointment Booking Module:** Handles the creation and status updates of doctor appointments.

6.  **Lab Test Booking Module:** Handles the creation and status updates of lab test bookings.

7.  **Booking History Module (Patient):** Allows patients to view past and upcoming doctor appointments and lab tests with their status.

8.  **E-Prescription Module:** Allows doctors to write prescriptions and patients to view and save them as PDFs.

---

## 💻 Tech Stack

* **Frontend (Mobile App):** Flutter (Dart)
* **Backend:** Firebase
* **Database:** Firebase Firestore (NoSQL)
* **Authentication:** Firebase Authentication
* **File Storage:** Firebase Storage (for potential future use like report uploads)
* **PDF Generation:** `pdf`, `printing` packages

---

## 🚀 Getting Started

Follow these instructions to set up and run the project locally for development.

### Prerequisites

* **Flutter SDK:** Make sure you have Flutter installed. Follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install).
* **Code Editor:** VS Code (recommended) or Android Studio.
* **Firebase Project:** Create a project on the [Firebase Console](https://console.firebase.google.com/).
* **(Optional) Git:** For cloning the repository.

### Setup

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/Kaya-Khurana/MediConnect.git](https://github.com/Kaya-Khurana/MediConnect.git)
    cd MediConnect/mediconnect
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup:**
    * Go to your Firebase project console.
    * **Enable Authentication:** Add the "Email/Password" sign-in method.
    * **Enable Firestore Database:** Create a Firestore database (start in **test mode** for development, secure later). Note the **location** you choose (e.g., `nam5 (us-central)`).
    * **(Optional) Enable Storage:** If you plan to add file uploads later.
    * **Register Apps:**
        * Add an **Android** app (follow instructions, download `google-services.json` and place it in `mediconnect/android/app/`).
        * Add an **iOS** app (follow instructions, download `GoogleService-Info.plist` and place it in `mediconnect/ios/Runner/`).
        * Add a **Web** app (follow instructions).
    * **Configure FlutterFire:** If you haven't already, install the Firebase CLI (`npm install -g firebase-tools`, `firebase login`) and FlutterFire CLI (`dart pub global activate flutterfire_cli`). Then run:
        ```bash
        flutterfire configure
        ```
        Select your Firebase project and choose the platforms (android, ios, web). This will generate `lib/firebase_options.dart`.

4.  **Firestore Indexes:** As you run the app and navigate to different screens (Admin Portal tabs, My Appointments, My Prescriptions, Lab Dashboard), Firestore might require composite indexes.
    * Run the app in **Debug Mode** (using the Run and Debug panel in VS Code).
    * When a screen shows a "Firestore Error: The required index..." message, check the **VS Code DEBUG CONSOLE**.
    * Firebase will provide a direct **URL** in the error message. Click this link.
    * The Firebase console will open with the index fields pre-filled. Click **"Create Index"**.
    * Wait for the index to build (status becomes "Enabled") before restarting the app.

### Running the App

1.  **Choose a Device:** Select a connected device (physical phone, emulator, or Chrome for web) in VS Code (bottom-right corner).
2.  **Run:**
    ```bash
    flutter run
    ```
    Or use the **Run and Debug** panel in VS Code (recommended for seeing index errors).

## 💡 Future Enhancements

* Implement Doctor availability slots.
* Add notifications for appointment confirmations/reminders.
* Implement patient medical report uploads (using Firebase Storage).
* Add search/filtering for doctors and labs.
* Implement secure deletion of user Authentication accounts (requires Cloud Functions).
* Refine UI/UX.

---

Feel free to contribute or report issues!
