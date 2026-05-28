import { Router } from "express";
import {
  getConversations,
  createOrGetConversation,
  getMessages,
  sendMessage,
  markConversationAsRead,
  searchUsersForMessage,
  saveFcmToken,
} from "../controllers/messageController.js";

const router = Router();

router.post("/fcm-token", saveFcmToken);

router.get("/users/search", searchUsersForMessage);

router.get("/conversations", getConversations);
router.post("/conversations", createOrGetConversation);
router.get("/conversations/:conversationId/messages", getMessages);
router.post("/conversations/:conversationId/messages", sendMessage);
router.patch("/conversations/:conversationId/read", markConversationAsRead);

export default router;