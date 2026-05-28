import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { emitNewMessage } from "../socket.js";
import { messaging } from "../services/firebaseService.js";

const prisma = new PrismaClient();

const userSelect = {
  id: true,
  firebase_uid: true,
  username: true,
  nickname: true,
  avatar_url: true,
  bio: true,
};

export const getConversations = async (req: Request, res: Response) => {
  const firebase_uid = req.query.firebase_uid as string | undefined;

  if (!firebase_uid) {
    return res.status(400).json({ message: "firebase_uid is required" });
  }

  try {
    const currentUser = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (!currentUser) {
      return res.status(404).json({ message: "Current user not found" });
    }

    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [
          { user1_id: currentUser.id },
          { user2_id: currentUser.id },
        ],
      },
      include: {
        user1: { select: userSelect },
        user2: { select: userSelect },
        messages: {
          orderBy: { created_at: "desc" },
          take: 1,
          include: {
            sender: { select: userSelect },
          },
        },
      },
      orderBy: { created_at: "desc" },
    });

    const result = await Promise.all(
      conversations.map(async (conversation) => {
        const otherUser =
          conversation.user1_id === currentUser.id
            ? conversation.user2
            : conversation.user1;

        const unreadCount = await prisma.message.count({
          where: {
            conversation_id: conversation.id,
            sender_id: { not: currentUser.id },
            is_read: false,
          },
        });

        return {
          id: conversation.id,
          user1_id: conversation.user1_id,
          user2_id: conversation.user2_id,
          created_at: conversation.created_at,
          other_user: otherUser,
          last_message: conversation.messages[0] || null,
          unread_count: unreadCount,
        };
      })
    );

    return res.json(result);
  } catch (error) {
    console.error("Lỗi getConversations:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

export const createOrGetConversation = async (req: Request, res: Response) => {
  const { firebase_uid, target_user_id, target_uid } = req.body;

  if (!firebase_uid || (!target_user_id && !target_uid)) {
    return res.status(400).json({
      message: "firebase_uid and target_user_id or target_uid are required",
    });
  }

  try {
    const currentUser = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (!currentUser) {
      return res.status(404).json({ message: "Current user not found" });
    }

    const targetUser = target_uid
      ? await prisma.user.findUnique({
          where: { firebase_uid: target_uid },
        })
      : await prisma.user.findUnique({
          where: { id: Number(target_user_id) },
        });

    if (!targetUser) {
      return res.status(404).json({ message: "Target user not found" });
    }

    if (currentUser.id === targetUser.id) {
      return res.status(400).json({ message: "Cannot create conversation with yourself" });
    }

    const user1_id = Math.min(currentUser.id, targetUser.id);
    const user2_id = Math.max(currentUser.id, targetUser.id);

    const conversation = await prisma.conversation.upsert({
      where: {
        user1_id_user2_id: {
          user1_id,
          user2_id,
        },
      },
      update: {},
      create: {
        user1_id,
        user2_id,
      },
      include: {
        user1: { select: userSelect },
        user2: { select: userSelect },
      },
    });

    const otherUser =
      conversation.user1_id === currentUser.id
        ? conversation.user2
        : conversation.user1;

    return res.json({
      ...conversation,
      other_user: otherUser,
    });
  } catch (error) {
    console.error("Lỗi createOrGetConversation:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

export const getMessages = async (req: Request, res: Response) => {
  const conversationId = Number(req.params.conversationId);
  const firebase_uid = req.query.firebase_uid as string | undefined;

  if (!conversationId || !firebase_uid) {
    return res.status(400).json({
      message: "conversationId and firebase_uid are required",
    });
  }

  try {
    const currentUser = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (!currentUser) {
      return res.status(404).json({ message: "Current user not found" });
    }

    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return res.status(404).json({ message: "Conversation not found" });
    }

    const isMember =
      conversation.user1_id === currentUser.id ||
      conversation.user2_id === currentUser.id;

    if (!isMember) {
      return res.status(403).json({ message: "You are not a member of this conversation" });
    }

    const messages = await prisma.message.findMany({
      where: { conversation_id: conversationId },
      include: {
        sender: { select: userSelect },
      },
      orderBy: { created_at: "asc" },
      take: 100,
    });

    return res.json(messages);
  } catch (error) {
    console.error("Lỗi getMessages:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

export const sendMessage = async (req: Request, res: Response) => {
  const conversationId = Number(req.params.conversationId);
  const { firebase_uid, content } = req.body;

  if (!conversationId || !firebase_uid || !content?.trim()) {
    return res.status(400).json({
      message: "conversationId, firebase_uid and content are required",
    });
  }

  try {
    const sender = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (!sender) {
      return res.status(404).json({ message: "Sender not found" });
    }

    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return res.status(404).json({ message: "Conversation not found" });
    }

    const isMember =
      conversation.user1_id === sender.id ||
      conversation.user2_id === sender.id;

    if (!isMember) {
      return res.status(403).json({ message: "You are not a member of this conversation" });
    }

    const message = await prisma.message.create({
      data: {
        conversation_id: conversationId,
        sender_id: sender.id,
        content: content.trim(),
      },
      include: {
        sender: { select: userSelect },
      },
    });

    await emitNewMessage(conversationId, message);

    const receiverId =
      conversation.user1_id === sender.id
        ? conversation.user2_id
        : conversation.user1_id;

    const receiverDevices = await prisma.userDevice.findMany({
      where: {
        user_id: receiverId,
      },
      select: {
        fcm_token: true,
      },
    });

    const tokens = receiverDevices
      .map((device) => device.fcm_token)
      .filter(Boolean);

    if (tokens.length > 0) {
      try {
        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: sender.nickname || sender.username,
            body: content.trim(),
          },
          data: {
            type: "chat",
            conversation_id: String(conversationId),
            sender_id: String(sender.id),
            sender_username: sender.username,
          },
          android: {
            priority: "high",
            notification: {
              channelId: "chat_messages",
              sound: "default",
            },
          },
        });
      } catch (pushError) {
        console.error("Lỗi gửi FCM notification:", pushError);
      }
    }

    return res.status(201).json(message);
  } catch (error) {
    console.error("Lỗi sendMessage:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

export const markConversationAsRead = async (req: Request, res: Response) => {
  const conversationId = Number(req.params.conversationId);
  const { firebase_uid } = req.body;

  if (!conversationId || !firebase_uid) {
    return res.status(400).json({
      message: "conversationId and firebase_uid are required",
    });
  }

  try {
    const currentUser = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (!currentUser) {
      return res.status(404).json({ message: "Current user not found" });
    }

    await prisma.message.updateMany({
      where: {
        conversation_id: conversationId,
        sender_id: { not: currentUser.id },
        is_read: false,
      },
      data: {
        is_read: true,
      },
    });

    return res.json({ message: "Marked as read" });
  } catch (error) {
    console.error("Lỗi markConversationAsRead:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
export const searchUsersForMessage = async (req: Request, res: Response) => {
  const q = (req.query.q as string | undefined)?.trim();
  const firebase_uid = req.query.firebase_uid as string | undefined;

  if (!firebase_uid) {
    return res.status(400).json({ message: "firebase_uid is required" });
  }

  if (!q) {
    return res.json([]);
  }

  try {
    const currentUser = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (!currentUser) {
      return res.status(404).json({ message: "Current user not found" });
    }

    const users = await prisma.user.findMany({
      where: {
        id: { not: currentUser.id },
        OR: [
          { username: { contains: q } },
          { nickname: { contains: q } },
          { email: { contains: q } },
        ],
      },
      select: userSelect,
      take: 20,
      orderBy: {
        username: "asc",
      },
    });

    return res.json(users);
  } catch (error) {
    console.error("Lỗi searchUsersForMessage:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

export const saveFcmToken = async (req: Request, res: Response) => {
  const { firebase_uid, fcm_token, platform } = req.body;

  if (!firebase_uid || !fcm_token) {
    return res.status(400).json({
      message: "firebase_uid and fcm_token are required",
    });
  }

  try {
    const user = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const device = await prisma.userDevice.upsert({
      where: {
        fcm_token,
      },
      update: {
        user_id: user.id,
        platform: platform || "android",
      },
      create: {
        user_id: user.id,
        fcm_token,
        platform: platform || "android",
      },
    });

    return res.json({
      message: "FCM token saved",
      device,
    });
  } catch (error) {
    console.error("Lỗi saveFcmToken:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};