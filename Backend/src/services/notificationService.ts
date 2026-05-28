import { PrismaClient, NotificationType } from '@prisma/client';

const prisma = new PrismaClient();

type CreateNotificationParams = {
  userId: number;      // người nhận thông báo
  actorId: number;     // người tạo hành động
  type: NotificationType;
  postId?: number | null;
};

export async function createNotification({
  userId,
  actorId,
  type,
  postId = null,
}: CreateNotificationParams) {
  // Không tự gửi thông báo cho chính mình
  if (userId === actorId) return null;

  return prisma.notification.create({
    data: {
      user_id: userId,
      actor_id: actorId,
      post_id: postId,
      type,
    },
  });
}