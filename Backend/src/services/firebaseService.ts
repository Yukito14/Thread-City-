import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import { getDatabase } from "firebase-admin/database";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const serviceAccountPath = path.join(
  __dirname,
  "../../serviceAccountKey.json"
);

console.log("[FIREBASE] Service account path:", serviceAccountPath);

if (!fs.existsSync(serviceAccountPath)) {
  throw new Error(
    `Không tìm thấy serviceAccountKey.json tại: ${serviceAccountPath}`
  );
}

if (!getApps().length) {
  initializeApp({
    credential: cert(serviceAccountPath),
    databaseURL: "https://thread-b4d7b-default-rtdb.firebaseio.com",
  });

  console.log("🔥 Firebase Admin initialized");
}

export const messaging = getMessaging();
export const rtdb = getDatabase();