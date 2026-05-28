import { Router } from "express";
import {
  getFeed,
  createPost,
  toggleLike,
  getReplies,
  getPostsByUserUid,
  getPostById,
} from "../controllers/postController.js";

const router = Router();

router.get("/", getFeed);
router.post("/", createPost);

router.get("/user/:firebase_uid", getPostsByUserUid);

router.get("/:id/replies", getReplies);
router.post("/:id/like", toggleLike);

// Route này để Flutter gọi GET /posts/:id
// Đặt cuối cùng để không ăn nhầm /user/:firebase_uid
router.get("/:id", getPostById);

export default router;