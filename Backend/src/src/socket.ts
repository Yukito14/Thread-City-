import { Server as HttpServer } from "http";
import { Server } from "socket.io";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

let io: Server | null = null;

export const initSocket = (server: HttpServer) => {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST", "PATCH"],
    },
  });

  io.on("connection", (socket) => {
    console.log(`[SOCKET] Connected: ${socket.id}`);

    socket.on("join_user", async (data: { firebase_uid: string }) => {
      try {
        const user = await prisma.user.findUnique({
          where: { firebase_uid: data.firebase_uid },
        });

        if (!user) {
          socket.emit("socket_error", { message: "User not found" });
          return;
        }

        socket.data.userId = user.id;
        socket.data.firebase_uid = user.firebase_uid;

        socket.join(`user:${user.id}`);
        console.log(`[SOCKET] User ${user.id} joined user:${user.id}`);
      } catch (error) {
        console.error("[SOCKET] join_user error:", error);
      }
    });

    socket.on("join_conversation", (data: { conversation_id: number }) => {
      socket.join(`conversation:${data.conversation_id}`);
      console.log(`[SOCKET] ${socket.id} joined conversation:${data.conversation_id}`);
    });

    socket.on("leave_conversation", (data: { conversation_id: number }) => {
      socket.leave(`conversation:${data.conversation_id}`);
      console.log(`[SOCKET] ${socket.id} left conversation:${data.conversation_id}`);
    });

    socket.on("typing", (data: { conversation_id: number; firebase_uid: string }) => {
      socket.to(`conversation:${data.conversation_id}`).emit("typing", data);
    });

    socket.on("stop_typing", (data: { conversation_id: number; firebase_uid: string }) => {
      socket.to(`conversation:${data.conversation_id}`).emit("stop_typing", data);
    });

    socket.on("disconnect", () => {
      console.log(`[SOCKET] Disconnected: ${socket.id}`);
    });
  });

  console.log("✅ Socket.IO initialized");
};

export const emitNewMessage = async (conversationId: number, message: any) => {
  if (!io) return;

  io.to(`conversation:${conversationId}`).emit("receive_message", message);

  const conversation = await prisma.conversation.findUnique({
    where: { id: conversationId },
    select: {
      user1_id: true,
      user2_id: true,
    },
  });

  if (conversation) {
    io.to(`user:${conversation.user1_id}`).emit("new_message_notification", message);
    io.to(`user:${conversation.user2_id}`).emit("new_message_notification", message);
  }
};