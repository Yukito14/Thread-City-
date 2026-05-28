import { Router } from "express";
import {
  getConversations,
  createOrGetConversation,
  getMessages,
  sendMessage,
  markConversationAsRead,
  searchUsersForMessage,
} from "../controllers/messageController.js";

const router = Router();

router.get("/users/search", searchUsersForMessage);

router.get("/conversations", getConversations);
router.post("/conversations", createOrGetConversation);
router.get("/conversations/:conversationId/messages", getMessages);
router.post("/conversations/:conversationId/messages", sendMessage);
router.patch("/conversations/:conversationId/read", markConversationAsRead);

export default router;